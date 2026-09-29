import 'dart:async';
import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../models/contact_request.dart';
import '../models/call_record.dart';
import '../models/profile.dart';
import '../models/active_connection.dart';
import '../services/contact_service.dart';
import '../services/presence_service.dart';
import '../services/database_service.dart';

class ContactProvider extends ChangeNotifier {
  final ContactService _contactService;
  final PresenceService _presenceService;
  final DatabaseService _databaseService;

  List<Contact> _contacts = [];
  List<Contact> get contacts => _contacts;

  List<ContactRequest> _incomingRequests = [];
  List<ContactRequest> get incomingRequests => _incomingRequests;

  List<Profile> _searchResults = [];
  List<Profile> get searchResults => _searchResults;

  List<CallRecord> _callHistory = [];
  List<CallRecord> get callHistory => _callHistory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _error;
  String? get error => _error;

  StreamSubscription? _presenceSub;

  ContactProvider({
    ContactService? contactService,
    PresenceService? presenceService,
    DatabaseService? databaseService,
  })  : _contactService = contactService ?? ContactService(),
        _presenceService = presenceService ?? PresenceService(),
        _databaseService = databaseService ?? DatabaseService();

  PresenceService get presenceService => _presenceService;

  /// Start listening to presence changes to update contact online status.
  void startPresenceListening() {
    _presenceSub = _presenceService.onOnlineUsersChanged.listen((_) {
      _enrichContactsWithStatus();
    });
  }

  /// Load contacts and incoming requests, then enrich with status.
  Future<void> loadContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _contactService.getContacts(),
        _contactService.getIncomingRequests(),
        _databaseService.getCallHistory(limit: 10),
      ]);

      _contacts = results[0] as List<Contact>;
      _incomingRequests = results[1] as List<ContactRequest>;
      _callHistory = results[2] as List<CallRecord>;

      // Enrich with online/connected status
      await _enrichContactsWithStatus();
    } catch (e) {
      _error = 'Failed to load contacts: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update contact isOnline and isConnectedToMe fields from presence + active_connections.
  Future<void> _enrichContactsWithStatus() async {
    if (_contacts.isEmpty) return;

    try {
      // Get active connections for all contacts
      final contactUserIds =
          _contacts.map((c) => c.profile.id).toList();
      final activeConnections = await _databaseService
          .getActiveConnectionsForUsers(contactUserIds);

      final connectionMap = <String, ActiveConnection>{};
      for (final conn in activeConnections) {
        connectionMap[conn.userId] = conn;
      }

      final myUserId = _databaseService.currentUserId;
      final myConnection =
          await _databaseService.getMyActiveConnection();

      _contacts = _contacts.map((contact) {
        final isOnline =
            _presenceService.isUserOnline(contact.profile.id);

        // Contact is connected to me if they're in the same direct room
        bool isConnectedToMe = false;
        if (myUserId != null && myConnection != null) {
          final expectedRoom = ActiveConnection.directRoomName(
              myUserId, contact.profile.id);
          final contactConn = connectionMap[contact.profile.id];
          isConnectedToMe = contactConn != null &&
              contactConn.roomName == expectedRoom &&
              myConnection.roomName == expectedRoom;
        }

        return contact.copyWith(
          isOnline: isOnline,
          isConnectedToMe: isConnectedToMe,
        );
      }).toList();
    } catch (e) {
      debugPrint('[ContactProvider] Status enrichment failed: $e');
    }

    notifyListeners();
  }

  /// Search for users
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _contactService.searchUsers(query);
    } catch (e) {
      _error = 'Search failed: $e';
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Send a contact request
  Future<bool> sendRequest(String toUserId) async {
    try {
      await _contactService.sendRequest(toUserId);
      _searchResults = _searchResults
          .where((p) => p.id != toUserId)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to send request: $e';
      notifyListeners();
      return false;
    }
  }

  /// Accept a contact request
  Future<bool> acceptRequest(ContactRequest request) async {
    try {
      await _contactService.acceptRequest(
        request.id,
        request.fromProfile.id,
      );
      _incomingRequests = _incomingRequests
          .where((r) => r.id != request.id)
          .toList();
      await _reloadContactsQuietly();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to accept request: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reject a contact request
  Future<bool> rejectRequest(ContactRequest request) async {
    try {
      await _contactService.rejectRequest(request.id);
      _incomingRequests = _incomingRequests
          .where((r) => r.id != request.id)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to reject request: $e';
      notifyListeners();
      return false;
    }
  }

  /// Remove a contact
  Future<bool> removeContact(Contact contact) async {
    try {
      await _contactService.removeContact(contact.profile.id);
      _contacts = _contacts.where((c) => c.id != contact.id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to remove contact: $e';
      notifyListeners();
      return false;
    }
  }

  /// Check if a user is already a contact
  bool isContact(String userId) {
    return _contacts.any((c) => c.profile.id == userId);
  }

  /// Check if a request is already pending for a user
  bool hasPendingRequest(String userId) {
    return _incomingRequests.any((r) => r.fromProfile.id == userId);
  }

  /// Reload call history (e.g. after a call ends).
  Future<void> refreshCallHistory() async {
    try {
      _callHistory = await _databaseService.getCallHistory(limit: 10);
      notifyListeners();
    } catch (e) {
      debugPrint('[ContactProvider] Failed to refresh call history: $e');
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _reloadContactsQuietly() async {
    try {
      _contacts = await _contactService.getContacts();
      await _enrichContactsWithStatus();
    } catch (_) {}
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    super.dispose();
  }
}
