import 'package:dio/dio.dart';
import 'package:manager/core/services/api_service.dart';
import 'package:manager/data/models/branch.dart';

class BranchRepository {
  final ApiService _api;

  BranchRepository(this._api);

  // 📦 GET ALL BRANCHES
  Future<List<Branch>> getBranches() async {
    try {
      final response = await _api.dio.get('/branches');
      final List data = response.data;
      return data.map((e) => Branch.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load branches: $e");
    }
  }

  // 🔍 GET BRANCH BY ID
  Future<Branch> getBranchById(int id) async {
    try {
      final response = await _api.dio.get('/branches/$id');
      return Branch.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to get branch: $e");
    }
  }

  // ➕ CREATE BRANCH
  Future<Branch> createBranch(Branch branch) async {
    try {
      final response = await _api.dio.post(
        '/branches',
        data: branch.toJson(),
      );
      return Branch.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        print("CHI TIẾT LỖI TỪ SERVER: ${e.response?.data}");

        final serverErrors = e.response?.data['errors'];
        if (serverErrors != null) {
          print("DANH SÁCH TRƯỜNG SAI: $serverErrors");
        }
      }

      throw Exception("Thất bại (422): ${e.response?.data ?? e.message}");
    } catch (e) {
      throw Exception("Lỗi hệ thống: $e");
    }
  }

  // ✏️ UPDATE BRANCH
  Future<Branch> updateBranch(int id, Branch branch) async {
    try {
      final response = await _api.dio.put(
        '/branches/$id',
        data: branch.toJson(),
      );

      return Branch.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to update branch: $e");
    }
  }

  // ❌ DELETE BRANCH
  Future<void> deleteBranch(int id) async {
    try {
      await _api.dio.delete('/branches/$id');
    } catch (e) {
      throw Exception("Failed to delete branch: $e");
    }
  }
}
