import 'package:flutter/material.dart';
import 'package:manager/data/models/branch.dart';
import 'package:manager/data/repositories/branch_repository.dart';

class BranchViewModel extends ChangeNotifier {
  final BranchRepository _repo;

  BranchViewModel(this._repo);

  List<Branch> branches = [];
  bool isLoading = false;
  String? error;

  // ================= GET ALL =================
  Future<void> fetchBranches() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      branches = await _repo.getBranches();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= CREATE =================
  Future<bool> createBranch(Branch branch) async {
    try {
      isLoading = true;
      notifyListeners();
      final newBranch = await _repo.createBranch(branch);
      branches.add(newBranch); // update UI luôn
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= UPDATE =================
  Future<bool> updateBranch(int id, Branch branch) async {
    try {
      isLoading = true;
      notifyListeners();

      final updated = await _repo.updateBranch(id, branch);
      final index = branches.indexWhere((e) => e.id == id);
      if (index != -1) {
        branches[index] = updated;
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= DELETE =================
  Future<bool> deleteBranch(int id) async {
    try {
      await _repo.deleteBranch(id);
      branches.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
