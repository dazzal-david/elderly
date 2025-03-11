import 'package:elderly_care/config/supabase_config.dart';

class EmergencyService {
  final _supabase = SupabaseConfig.supabase;
  final String _currentUser = 'dazzal-david';
  static final DateTime _currentTime = DateTime.parse('2025-02-20 16:56:21');

  Future<void> sendEmergencyAlert({String? additionalNotes}) async {
    try {
      // Get user's profile and emergency contact information
      final userProfile = await _supabase
          .from('profiles')
          .select('name, emergency_contact_name, emergency_contact_phone')
          .eq('username', _currentUser)
          .single();

      // Create emergency alert record
      final alertResponse = await _supabase
          .from('emergency_alerts')
          .insert({
            'username': _currentUser,
            'user_name': userProfile['name'],
            'status': 'active',
            'emergency_contact_name': userProfile['emergency_contact_name'],
            'emergency_contact_phone': userProfile['emergency_contact_phone'],
            'notes': additionalNotes,
            'location': null, // TODO: Implement location services
            'created_at': _currentTime.toIso8601String(),
            'updated_at': _currentTime.toIso8601String(),
          })
          .select()
          .single();

      // Log the emergency alert
      await _logEmergencyEvent(
        alertId: alertResponse['id'],
        eventType: 'alert_created',
        details: 'Emergency alert initiated by user',
      );

      // Notify caregivers
      await _notifyCaregivers(alertResponse['id']);
    } catch (e) {
      await _logEmergencyEvent(
        eventType: 'alert_failed',
        details: 'Failed to create emergency alert: $e',
      );
      rethrow;
    }
  }

  Future<void> cancelEmergencyAlert(String alertId) async {
    try {
      await _supabase
          .from('emergency_alerts')
          .update({
            'status': 'cancelled',
            'updated_at': _currentTime.toIso8601String(),
            'cancelled_at': _currentTime.toIso8601String(),
            'cancelled_by': _currentUser,
          })
          .eq('id', alertId)
          .eq('username', _currentUser);

      await _logEmergencyEvent(
        alertId: alertId,
        eventType: 'alert_cancelled',
        details: 'Emergency alert cancelled by user',
      );
    } catch (e) {
      await _logEmergencyEvent(
        alertId: alertId,
        eventType: 'cancel_failed',
        details: 'Failed to cancel emergency alert: $e',
      );
      rethrow;
    }
  }

  Future<void> updateEmergencyAlert(String alertId, {
    String? notes,
    String? status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = {
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
        if (additionalData != null) ...additionalData,
        'updated_at': _currentTime.toIso8601String(),
      };

      await _supabase
          .from('emergency_alerts')
          .update(updateData)
          .eq('id', alertId)
          .eq('username', _currentUser);

      await _logEmergencyEvent(
        alertId: alertId,
        eventType: 'alert_updated',
        details: 'Emergency alert updated with new information',
      );
    } catch (e) {
      await _logEmergencyEvent(
        alertId: alertId,
        eventType: 'update_failed',
        details: 'Failed to update emergency alert: $e',
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    return await _supabase
        .from('emergency_alerts')
        .select()
        .eq('username', _currentUser)
        .eq('status', 'active')
        .order('created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> watchActiveAlerts() {
    return _supabase
        .from('emergency_alerts')
        .stream(primaryKey: ['id'])
        .eq('username', _currentUser)
        .map((rows) {
          final List<Map<String, dynamic>> filteredRows = rows
            .where((row) => row['status'] == 'active')
            .toList()
            ..sort((a, b) => 
              DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at']))
            );
          return filteredRows;
        });
}

  Future<Map<String, dynamic>?> getEmergencyContactInfo() async {
    final response = await _supabase
        .from('profiles')
        .select('emergency_contact_name, emergency_contact_phone')
        .eq('username', _currentUser)
        .single();
    
    return {
      'name': response['emergency_contact_name'],
      'phone': response['emergency_contact_phone'],
    };
  }

  Future<void> updateEmergencyContacts({
    required String contactName,
    required String contactPhone,
  }) async {
    await _supabase
        .from('profiles')
        .update({
          'emergency_contact_name': contactName,
          'emergency_contact_phone': contactPhone,
          'updated_at': _currentTime.toIso8601String(),
        })
        .eq('username', _currentUser);
  }

  Future<void> _logEmergencyEvent({
    String? alertId,
    required String eventType,
    required String details,
  }) async {
    await _supabase
        .from('emergency_event_logs')
        .insert({
          'alert_id': alertId,
          'username': _currentUser,
          'event_type': eventType,
          'details': details,
          'created_at': _currentTime.toIso8601String(),
        });
  }

  Future<void> _notifyCaregivers(String alertId) async {
    // Get associated caregivers
    final caregivers = await _supabase
        .from('caregiver_associations')
        .select('caregiver_username')
        .eq('elderly_username', _currentUser)
        .eq('status', 'active');

    // Create notifications for each caregiver
    for (final caregiver in caregivers) {
      await _supabase
          .from('caregiver_notifications')
          .insert({
            'caregiver_username': caregiver['caregiver_username'],
            'alert_id': alertId,
            'type': 'emergency_alert',
            'status': 'pending',
            'created_at': _currentTime.toIso8601String(),
          });
    }
  }

  Future<bool> verifyEmergencySystem() async {
    try {
      // Check if we can access necessary tables
      await Future.wait([
        _supabase.from('emergency_alerts').select().limit(1),
        _supabase.from('profiles').select().limit(1),
        _supabase.from('caregiver_associations').select().limit(1),
      ]);

      // Check if emergency contact is set up
      final contactInfo = await getEmergencyContactInfo();
      if (contactInfo == null || 
          contactInfo['name'] == null || 
          contactInfo['phone'] == null) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Additional helper methods for active alerts
  Stream<int> watchActiveAlertsCount() {
    return watchActiveAlerts().map((alerts) => alerts.length);
  }

  Future<bool> hasActiveAlerts() async {
    final alerts = await getActiveAlerts();
    return alerts.isNotEmpty;
  }
}