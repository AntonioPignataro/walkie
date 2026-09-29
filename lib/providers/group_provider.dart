import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/database_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService;
  final DatabaseService _databaseService;

  List<Group> _groups = [];
  List<Group> get groups => _groups;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  GroupProvider({
    GroupService? groupService,
    DatabaseService? databaseService,
  })  : _groupService = groupService ?? GroupService(),
        _databaseService = databaseService ?? DatabaseService();

  /// Load all groups the user belongs to, with connected member info.
  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _groupService.getMyGroups();
      await _enrichGroupsWithConnectedStatus();
    } catch (e) {
      _error = 'Failed to load groups: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update groups with which members are currently connected.
  Future<void> _enrichGroupsWithConnectedStatus() async {
    try {
      _groups = await Future.wait(_groups.map((group) async {
        final connectedIds =
            await _databaseService.getGroupConnectedUserIds(group.id);
        final connectedSet = connectedIds.toSet();

        final updatedMembers = group.members.map((m) {
          return m.copyWith(
            isConnected: connectedSet.contains(m.profile.id),
          );
        }).toList();

        return group.copyWith(members: updatedMembers);
      }));
    } catch (e) {
      debugPrint('[GroupProvider] Connected status enrichment failed: $e');
    }
  }

  /// Refresh connected member status for all groups.
  Future<void> refreshConnectedStatus() async {
    await _enrichGroupsWithConnectedStatus();
    notifyListeners();
  }

  /// Create a new group
  Future<Group?> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
      );
      _groups = [group, ..._groups];
      notifyListeners();
      return group;
    } catch (e) {
      _error = 'Failed to create group: $e';
      notifyListeners();
      return null;
    }
  }

  /// Add a contact to a group
  Future<bool> addMember(String groupId, String userId) async {
    try {
      await _groupService.addMember(groupId, userId);
      await _reloadGroupQuietly(groupId);
      return true;
    } catch (e) {
      _error = 'Failed to add member: $e';
      notifyListeners();
      return false;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    try {
      await _groupService.leaveGroup(groupId);
      _groups = _groups.where((g) => g.id != groupId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to leave group: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _reloadGroupQuietly(String groupId) async {
    try {
      final members = await _groupService.getGroupMembers(groupId);
      _groups = _groups.map((g) {
        if (g.id == groupId) return g.copyWith(members: members);
        return g;
      }).toList();
      notifyListeners();
    } catch (_) {}
  }
}
