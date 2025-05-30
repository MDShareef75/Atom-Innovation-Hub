import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:atoms_innovation_hub/models/user_model.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Online users stream
  Stream<QuerySnapshot> get onlineUsers {
    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots();
  }

  // User model stream
  Stream<UserModel?> userModelStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        data['id'] = snapshot.id;
        return UserModel.fromJson(data);
      } else {
        return null;
      }
    });
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, String name, {String? phoneNumber}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      await _createUserDocument(userCredential.user!, name, phoneNumber: phoneNumber);
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password, {bool rememberMe = false}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if user is disabled
      await _checkUserStatus(userCredential.user!.uid);
      
      // Update last login timestamp
      await _updateLastLogin(userCredential.user!.uid);
      
      // Save credentials for remember me
      await saveCredentials(email, password, rememberMe);
      
      // Set online status
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if user document exists, if not create one
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!, googleUser.displayName ?? 'User');
      } else {
        // Check if existing user is disabled
        await _checkUserStatus(userCredential.user!.uid);
        await _updateLastLogin(userCredential.user!.uid);
      }
      
      // Set online status
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut({bool clearRememberedCredentials = false}) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': false,
        });
      }
      if (clearRememberedCredentials) {
        await clearSavedCredentials();
      } else {
        final savedCreds = await getSavedCredentials();
        if (!savedCreds['rememberMe']) {
          await clearSavedCredentials();
        }
      }
      
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String name, {String? phoneNumber}) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'name': name,
        'photoUrl': user.photoURL ?? '',
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'phoneNumber': phoneNumber,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      print('🔍 AuthService: Checking admin status for userId: $userId');
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      print('📄 AuthService: Document exists: ${doc.exists}');
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('📋 AuthService: User data: $data');
        final isAdmin = data['isAdmin'] ?? false;
        print('🎯 AuthService: isAdmin field value: $isAdmin (type: ${isAdmin.runtimeType})');
        return isAdmin;
      }
      print('❌ AuthService: Document does not exist, returning false');
      return false;
    } catch (e) {
      print('💥 AuthService: Error checking admin status: $e');
      return false;
    }
  }

  // Check user status
  Future<void> _checkUserStatus(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['isDisabled'] == true) {
          // Sign out the user immediately
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'Your account has been disabled. Please contact support.',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    File? imageFile,
    Uint8List? webImageBytes,
    String? imageName,
  }) async {
    try {
      print('Starting profile update for user: $userId');
      Map<String, dynamic> updateData = {};
      
      // Update name if provided
      if (name != null && name.isNotEmpty) {
        updateData['name'] = name;
        print('Updating name to: $name');
      }
      
      // Upload and update photo if provided
      if (imageFile != null) {
        print('Uploading mobile image file...');
        final photoUrl = await _uploadImage(imageFile, 'profile_images/$userId');
        updateData['photoUrl'] = photoUrl;
        print('Mobile image uploaded successfully. URL: $photoUrl');
      } else if (webImageBytes != null) {
        print('Uploading web image bytes...');
        final photoUrl = await _uploadWebImage(webImageBytes, 'profile_images/$userId', imageName ?? 'profile.jpg');
        updateData['photoUrl'] = photoUrl;
        print('Web image uploaded successfully. URL: $photoUrl');
      }
      
      // Update Firestore document
      if (updateData.isNotEmpty) {
        print('Updating Firestore with data: $updateData');
        await _firestore.collection('users').doc(userId).update(updateData);
        print('Firestore update completed successfully');
      } else {
        print('No data to update');
      }
    } catch (e) {
      print('Error in updateProfile: $e');
      rethrow;
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Upload web image to Firebase Storage
  Future<String> _uploadWebImage(Uint8List bytes, String path, String imageName) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putData(bytes);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Remember Me functionality
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  // Save credentials for remember me
  Future<void> saveCredentials(String email, String password, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
    
    if (rememberMe) {
      await prefs.setString(_savedEmailKey, email);
      await prefs.setString(_savedPasswordKey, password);
    } else {
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
    }
  }

  // Get saved credentials
  Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final email = prefs.getString(_savedEmailKey) ?? '';
    final password = prefs.getString(_savedPasswordKey) ?? '';
    
    return {
      'rememberMe': rememberMe,
      'email': email,
      'password': password,
    };
  }

  // Clear saved credentials
  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
  }

  // Check if user should be auto-logged in
  Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final email = prefs.getString(_savedEmailKey) ?? '';
    final password = prefs.getString(_savedPasswordKey) ?? '';
    
    return rememberMe && email.isNotEmpty && password.isNotEmpty;
  }

  // Auto login with saved credentials
  Future<UserCredential?> autoLogin() async {
    try {
      final savedCreds = await getSavedCredentials();
      if (savedCreds['rememberMe'] && 
          savedCreds['email'].isNotEmpty && 
          savedCreds['password'].isNotEmpty) {
        
        return await signInWithEmailAndPassword(
          savedCreds['email'], 
          savedCreds['password'],
          rememberMe: true, // Keep remember me active
        );
      }
      return null;
    } catch (e) {
      print('Auto login failed: $e');
      // Clear invalid credentials
      await clearSavedCredentials();
      return null;
    }
  }
} 