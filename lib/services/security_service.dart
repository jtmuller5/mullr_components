import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:mullr_components/models/user.dart';
import 'package:mullr_components/services/file_service.dart';
import 'package:mullr_components/services/user_service.dart';
import 'package:pointycastle/export.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:stacked/stacked.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:steel_crypt/steel_crypt.dart';

class SecurityService with ReactiveServiceMixin {
  /// Key generation utilities
  RsaKeyHelper rsaKeyHelper = RsaKeyHelper(); // From rsa_encrypt
  //PlatformStringCryptor cryptor = PlatformStringCryptor(); // From flutter_string_encryption

  /// Holder variables
  AsymmetricKeyPair? keyPair;
  Encrypter? encrypter;
  Encrypter? aesEncrypter;
  LightCrypt? lightCrypt;
  PassCrypt passCrypt = PassCrypt.pbkdf2(algo: HmacHash.Sha_256);
  HashCrypt hashCrypt = HashCrypt(algo: HashAlgo.Sha_256);
  IV iv = IV.fromLength(16);
  String? publicKeyPem;
  String? privateKeyPem;

  //BiometricStorage biometricStorage = BiometricStorage();
  static const FlutterSecureStorage flutterSecureStorage = FlutterSecureStorage();

  /// Constants
  static const String bioStorageFileName = 'tp_bio_storage';

  /// Creates instances of RSA utilities
  void initializeSecurityService() {
    print('initializing security');
  }

  /// Looks in secure storage for public/private keys for this user
  /// If they exist, creates the encryptor for this service
  Future<void> checkForExistingKeys() async {
    publicKeyPem = await readSecureData('publicKey_${FirebaseAuth.instance.currentUser?.uid}');
    privateKeyPem = await readSecureData('privateKey_${FirebaseAuth.instance.currentUser?.uid}');

    if (publicKeyPem != null && privateKeyPem != null) {
      RSAPrivateKey privateKey = rsaKeyHelper.parsePrivateKeyFromPem(privateKeyPem);
      RSAPublicKey publicKey = rsaKeyHelper.parsePublicKeyFromPem(publicKeyPem);

      createEncrypters(genKeyPair: AsymmetricKeyPair(publicKey, privateKey));
      print('found existing RSA keys');
    } else {
      await generateRSAKeys();
      createEncrypters(genKeyPair: keyPair);
      print('generated new RSA keys');
    }
  }

  /// Rivest–Shamir–Adleman public-key cryptosystem
  /// Uses the rsa_encrypt package to generate a Asymmetric key pair
  /// Will store keys in flutter_secure_storage as PEM strings
  /// TODO use Diffe Hellman to create shared secrets
  Future<void> generateRSAKeys() async {
    // Generates an AsymmetricKeyPair<PublicKey, PrivateKey> given a FortunaRandom RNG
    // May take a little while
    AsymmetricKeyPair _keyPair = await rsaKeyHelper.computeRSAKeyPair(rsaKeyHelper.getSecureRandom());

    print('pair: ' + _keyPair.toString());

    publicKeyPem = rsaKeyHelper.encodePublicKeyToPemPKCS1(_keyPair.publicKey as RSAPublicKey);
    privateKeyPem = rsaKeyHelper.encodePrivateKeyToPemPKCS1(_keyPair.privateKey as RSAPrivateKey);

    if (publicKeyPem != null && privateKeyPem != null) {
      // Immediately save pair to flutter_secure_storage
      writeSecureData('privateKey_${FirebaseAuth.instance.currentUser?.uid}', privateKeyPem!);
      writeSecureData('publicKey_${FirebaseAuth.instance.currentUser?.uid}', publicKeyPem!);
    }

    // TODO don't save this
    keyPair = _keyPair;
    notifyListeners();
  }

  /// Using the generated RSA keys, create an Encrypter object from the encrypt package
  void createEncrypters({
    required AsymmetricKeyPair? genKeyPair,
    RSAEncoding encoding = RSAEncoding.PKCS1,
  }) {
    try {
      encrypter = Encrypter(
        RSA(
          privateKey: genKeyPair?.privateKey as RSAPrivateKey,
          publicKey: genKeyPair?.publicKey as RSAPublicKey,
          encoding: encoding,
        ),
      );

      print('RSA encrypter created successfully');

      aesEncrypter = Encrypter(
        AES(
          Key.fromUtf8('my 32 length key................'),
          mode: AESMode.sic,
          padding: null,
        ),
      );

      print('AES encrypter created successfully');
      notifyListeners();
    } catch (e) {
      print('encrypter creation error: ' + e.toString());
    }
  }

  /// Writes a value to a single key in secure storage
  Future writeSecureData(String key, String value) async {
    var writeData = await flutterSecureStorage.write(key: key, value: value);
    return writeData;
  }

  /// Reads the value stored at a single key in secure storage
  Future readSecureData(String key) async {
    var readData = await flutterSecureStorage.read(key: key);
    return readData;
  }

  /// Deletes the value stored at a single key in secure storage
  Future deleteSecureData(String key) async {
    var deleteData = await flutterSecureStorage.delete(key: key);
    return deleteData;
  }

  Future<void> deleteAllSecureData() async {
    var deleteData = await flutterSecureStorage.deleteAll();
    return deleteData;
  }

  /// Generate a random salt and use the PassCrypt object to hash the user's password
  /// Save the salt and hashed password to Firestore
  Future<String> hashPassword(String password) async {
    String salt = CryptKey().genDart(len: 4);

    print('First salt: ' + salt);
    String hashedPassword = passCrypt.hash(salt: base64.encode(utf8.encode(salt)), inp: password);

    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
      'hashedPassword': hashedPassword,
      'salt': salt,
    });

    // Update the user
    User? user = GetIt.instance.get<UserService>().user;
    user?.salt = salt;
    user?.hashedPassword = hashedPassword;

    if (user != null) GetIt.instance.get<UserService>().updateUser(user);

    return hashedPassword;
  }

  /// Create a key using the Advanced Encryption Standard (AES) - steel_crypt package
  /// https://stackoverflow.com/questions/54995723/aes-encryption-in-flutter
  Future<void> generateLightEncrypterFromPassword(String password) async {
    print('Hashed pass: ' + hashCrypt.hash(inp: password));

    //generate AES encrypter with key and PKCS7 padding
    lightCrypt = LightCrypt(
      algo: StreamAlgo.salsa20,
      key: base64Encode(utf8.encode(hashCrypt.hash(inp: password))),
    );
  }

  /// Use the previously created LightCrypt to encrypt the user's keys and save those to Firestore
  Future<void> encryptAndSavePems() async {
    if (publicKeyPem != null && privateKeyPem != null) {
      print('Encrypting and saving keys');
      String? encryptedPublicKeyPem = encryptWithPassPhraseEncrypter(publicKeyPem!);
      String? encryptedPrivateKeyPem = encryptWithPassPhraseEncrypter(privateKeyPem!);

      // Save the nonce to Firestore. This will be used when the user goes to recover an account
      // On the new device, they will enter the passphrase, combine that with the nonce, and verify that they are getting the right values
      // If it's correct, decrypt the encrypted PEMs and save those in the new secure storage
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
        'encryptedPublicKeyPem': encryptedPublicKeyPem,
        'encryptedPrivateKeyPem': encryptedPrivateKeyPem,
      });

      // Update the user
      User? user = GetIt.instance.get<UserService>().user;
      user?.encryptedPublicKeyPem = encryptedPublicKeyPem;
      user?.encryptedPrivateKeyPem = encryptedPrivateKeyPem;

      if (user != null) GetIt.instance.get<UserService>().updateUser(user);
    } else {
      print('Keys are null');
    }
  }

  String? encryptWithPassPhraseEncrypter(String data) {
    if (lightCrypt != null && GetIt.instance.get<UserService>().user?.salt != null) {
      print('LightCrypt Key: ' + lightCrypt!.key);
      print('Salt: ' + GetIt.instance.get<UserService>().user!.salt!);
      print('Base 64 Salt: ' + base64Decode(GetIt.instance.get<UserService>().user!.salt!).length.toString());
      print('UTF 8 Salt: ' + utf8.encode(GetIt.instance.get<UserService>().user!.salt!).toString());
      print('UTF 8 Length: ' + utf8.encode(GetIt.instance.get<UserService>().user!.salt!).length.toString());

      //CryptKey().genDart(8);

      //encrypt using GCM
      String encrypted = lightCrypt!.encrypt(
        inp: data,
        iv: base64.encode(utf8.encode(GetIt.instance.get<UserService>().user!.salt!)),
      );

      return encrypted;
    }
  }

  String? decryptWithPassphraseEncrypter(String encrypted) {
    if (lightCrypt != null && GetIt.instance.get<UserService>().user?.salt != null) {
      //decrypt
      String decrypted = lightCrypt!.decrypt(
        enc: encrypted,
        iv: base64.encode(utf8.encode(GetIt.instance.get<UserService>().user!.salt!)),
      );

      return decrypted;
    }
  }

  /// Local Authentication
  /// TODO iOS setup
  LocalAuthentication localAuth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    return await localAuth.canCheckBiometrics;
  }

  /// Check the available biometrics on the deve, called from profileView before requesting authentication
  Future<List<BiometricType>> availableBiometrics() async {
    List<BiometricType> availableBiometrics = await localAuth.getAvailableBiometrics();

    print('Available biometrics: ' + availableBiometrics.toString());

    if (Platform.isIOS) {
      if (availableBiometrics.contains(BiometricType.face)) {
        // Face ID.
        print('iOS biometrics contains Face ID');
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        // Touch ID.
        print('iOS biometrics contains Touch ID');
      }
    }

    return availableBiometrics;
  }

  Future<bool> requestAuthentication({String message = 'Please authenticate'}) async {
    try {
      bool didAuthenticate = await localAuth.authenticateWithBiometrics(
        localizedReason: 'Please authenticate to show account balance',
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        print('Authentication failed: ' + (e.message ?? 'Error'));
        return false;
      } else if (e.code == auth_error.lockedOut) {
        print('Authentication failed: ' + (e.message ?? 'Error'));
        return false;
      } else if (e.code == auth_error.notEnrolled) {
        print('Authentication failed: ' + (e.message ?? 'Error'));
        return false;
      } else if (e.code == auth_error.passcodeNotSet) {
        print('Authentication failed: ' + (e.message ?? 'Error'));
        return false;
      } else if (e.code == auth_error.permanentlyLockedOut) {
        print('Authentication failed: ' + (e.message ?? 'Error'));
        return false;
      } else if (e.code == auth_error.otherOperatingSystem) {
        print('Authentication failed: ' + (e.message ?? 'Error'));
        return false;
      } else {
        print('authentication failed: ' + e.toString());
        return false;
      }
    }
  }

  // Save the video to an app specific directory
  // https://flutter.dev/docs/cookbook/persistence/reading-writing-files
  Future<File> getNewFile() async {
    return await FileService().getFile(temp: false, folders: 'videos/', extension: 'mp4');
  }

  File? newFile;

  bool first = true;

  List<int> videoBytes = [];

  /// Video Encryption Methods
  /// https://stackoverflow.com/questions/27765878/how-to-create-a-streamtransformer-in-dart
  StreamTransformer<Uint8List, dynamic> streamEncrypter = StreamTransformer<Uint8List, dynamic>.fromHandlers(
    handleData: (Uint8List data, EventSink sink) async {
      int numberOfBytes = data.length;

      print('length: ' + numberOfBytes.toString());

      Uint8List encryptedVideo =
          GetIt.instance.get<SecurityService>().aesEncrypter!.encryptBytes(data, iv: GetIt.instance.get<SecurityService>().iv).bytes;

      print('encrypted chunk: ' + encryptedVideo.toString());

      GetIt.instance.get<SecurityService>().videoBytes.addAll(encryptedVideo.toList());
      if (GetIt.instance.get<SecurityService>().first) {
        print('First file write');
        GetIt.instance.get<SecurityService>().first = false;
        GetIt.instance.get<SecurityService>().newFile?.writeAsBytes(encryptedVideo);
      } else {
        print('Append file write');
        GetIt.instance.get<SecurityService>().newFile?.writeAsBytes(encryptedVideo, mode: FileMode.append);
      }

      Uint8List? size = await GetIt.instance.get<SecurityService>().newFile?.readAsBytes();
      print('size: ' + (size?.length ?? 0).toString());

      try {
        sink.add(encryptedVideo);
      } catch (e) {
        print('Error adding encrypted video to stream: ' + e.toString());
      }
    },
    handleError: (error, stackTrace, sink) {
      print('Stream error: ' + error.toString());
    },
  );

  StreamTransformer<Uint8List, dynamic> streamDecrypter = StreamTransformer<Uint8List, dynamic>.fromHandlers(
    handleData: (Uint8List data, EventSink sink) {
      int numberOfBytes = data.length;

      print('length: ' + numberOfBytes.toString());

      Uint8List decryptedVideo = Uint8List.fromList(GetIt.instance.get<SecurityService>().aesEncrypter!.decryptBytes(
            Encrypted(data),
            iv: GetIt.instance.get<SecurityService>().iv,
          ));

      sink.add(decryptedVideo);
    },
    handleError: (error, stackTrace, sink) {
      print('Stream error: ' + error.toString());
    },
  );
}
