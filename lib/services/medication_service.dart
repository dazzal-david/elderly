import 'package:elderly_care/config/supabase_config.dart';
import 'package:elderly_care/models/medication_model.dart';

class MedicationService {
  final _supabase = SupabaseConfig.supabase;
  static const String _tableName = 'medications';
  static final DateTime _currentTime = DateTime.parse('2025-02-21 14:53:12');

  // Get current user's username dynamically
  String get _currentUser {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('User not authenticated');
    return email.split('@')[0].toLowerCase();
  }

  Stream<List<Medication>> getMedicationsStream() {
    try {
      return _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('username', _currentUser)
          .map((rows) => rows.map((row) => Medication.fromJson(row)).toList());
    } catch (e) {
      print('Error in getMedicationsStream: $e');
      return Stream.value([]);
    }
  }

  Future<List<Medication>> getTodaysMedications() async {
    try {
      final startOfDay = DateTime(_currentTime.year, _currentTime.month, _currentTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('username', _currentUser)
          .lte('start_date', _currentTime.toIso8601String())
          .or('end_date.is.null,end_date.gte.${_currentTime.toIso8601String()}')
          .eq('is_active', true);

      final medications = response.map((row) => Medication.fromJson(row)).toList();
      
      return medications.where((medication) {
        return medication.schedule.any((scheduleTime) {
          final scheduleDateTime = DateTime(
            _currentTime.year,
            _currentTime.month,
            _currentTime.day,
            scheduleTime.hour,
            scheduleTime.minute,
          );
          return scheduleDateTime.isAfter(startOfDay) && 
                 scheduleDateTime.isBefore(endOfDay);
        });
      }).toList();
    } catch (e) {
      print('Error in getTodaysMedications: $e');
      return [];
    }
  }

  // Update all other methods to use the getter instead of the hardcoded value
  Future<Medication> addMedication(Medication medication) async {
    try {
      final response = await _supabase.from(_tableName).insert({
        ...medication.toJson(),
        'username': _currentUser,
        'created_at': _currentTime.toIso8601String(),
      }).select().single();
      
      return Medication.fromJson(response);
    } catch (e) {
      print('Error in addMedication: $e');
      rethrow;
    }
  }

  // Update other methods similarly...
  // (Keep all other methods the same but replace the hardcoded _currentUser with the getter)
    Future<Medication> updateMedication(Medication medication) async {
    final response = await _supabase
        .from(_tableName)
        .update({
          ...medication.toJson(),
          'updated_at': _currentTime.toIso8601String(),
        })
        .eq('id', medication.id)
        .eq('username', _currentUser)
        .select()
        .single();
    
    return Medication.fromJson(response);
  }

  Future<Map<String, int>> getMedicationStats() async {
    final response = await _supabase
        .from(_tableName)
        .select('is_active, id')
        .eq('username', _currentUser);

    final activeCount = response.where((row) => row['is_active'] == true).length;
    final inactiveCount = response.where((row) => row['is_active'] == false).length;

    return {
      'active': activeCount,
      'inactive': inactiveCount,
      'total': response.length,
    };
  }


  Future<void> markMedicationTaken(String medicationId, DateTime scheduleTime) async {
    try {
      await _supabase.from('medication_logs').insert({
        'medication_id': medicationId,
        'username': _currentUser,
        'taken_at': _currentTime.toIso8601String(),
        'scheduled_time': scheduleTime.toIso8601String(),
      });
    } catch (e) {
      print('Error in markMedicationTaken: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getMedicationLogsStream(String medicationId) {
    try {
      return _supabase
          .from('medication_logs')
          .stream(primaryKey: ['id'])
          .eq('username', _currentUser)
          .map((rows) {
            final List<Map<String, dynamic>> filteredRows = rows
              .where((row) => row['medication_id'] == medicationId)
              .toList()
              ..sort((a, b) => 
                DateTime.parse(a['taken_at']).compareTo(DateTime.parse(b['taken_at']))
              );
            return filteredRows;
          });
    } catch (e) {
      print('Error in getMedicationLogsStream: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Medication>> getTodaysMedicationsStream() {
    return getMedicationsStream().map((medications) {
      final startOfDay = DateTime(_currentTime.year, _currentTime.month, _currentTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return medications.where((medication) {
        return medication.schedule.any((scheduleTime) {
          final scheduleDateTime = DateTime(
            _currentTime.year,
            _currentTime.month,
            _currentTime.day,
            scheduleTime.hour,
            scheduleTime.minute,
          );
          return scheduleDateTime.isAfter(startOfDay) && 
                 scheduleDateTime.isBefore(endOfDay);
        });
      }).toList();
    });
  }


  // Add error handling for authentication errors
  void _checkAuthentication() {
    if (_supabase.auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
  }
}