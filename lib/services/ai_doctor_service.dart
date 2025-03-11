import 'dart:convert';
import 'dart:async';  // Add this import for TimeoutException
import 'package:http/http.dart' as http;
import 'package:elderly_care/config/supabase_config.dart';

class AIDoctorService {
  final _supabase = SupabaseConfig.supabase;
  static final DateTime _currentTime = DateTime.parse('2025-03-10 18:10:30');
  static const String _currentUser = 'dazzal-david';

  static const String _baseUrl = 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3';
  static const String _apiKey = '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';

  Future<String> getResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': '''<|im_start|>system
You are an AI medical assistant for Senior Citizens. Provide a single, helpful response while:
1. Messages should be easy to understand and short
2. Recommending professional consultation for serious issues
3. Using clear, simple language
4. Being empathetic and helpful
5. Only respond once and do not generate follow-up conversations
<|im_end|>
<|im_start|>user
$message

<|im_start|>assistant''',
          'parameters': {
            'max_length': 300,
            'temperature': 0.7,
            'top_p': 0.9,
            'stop': ['<|im_end|>', '<|im_start|>'],
            'return_full_text': false
          }
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw 'Request timed out';
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data[0]['generated_text'] ?? 
          'I apologize, but I was unable to generate a response.';
        
        // Clean up the response
        aiResponse = aiResponse.split('\nUser:')[0].trim();
        aiResponse = aiResponse.split('\nAI Doctor:')[0].trim();
        
        await _saveConversation(message, aiResponse);
        return aiResponse;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _getOfflineResponse();
      }
    } catch (e) {
      print('Error in getResponse: $e');
      return _getOfflineResponse();
    }
  }

  String _getOfflineResponse() {
    return '''I apologize, but I'm currently experiencing technical difficulties. 
    As an AI medical assistant, I recommend:
    
    1. For non-urgent matters, please try again in a few moments
    2. For medical advice, consult your healthcare provider
    3. For emergencies, call emergency services immediately
    
    Remember: I'm an AI assistant and cannot replace professional medical care.''';
  }

  Future<void> _saveConversation(String userMessage, String aiResponse) async {
    try {
      await _supabase.from('ai_conversations').insert({
        'username': _currentUser,
        'user_message': userMessage,
        'ai_response': aiResponse,
        'created_at': _currentTime.toIso8601String(),
        'context': 'medical_assistant',
        'model': 'Mistral-7B'
      });
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    try {
      final response = await _supabase
          .from('ai_conversations')
          .select()
          .eq('username', _currentUser)
          .order('created_at', ascending: false)
          .limit(50);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching conversation history: $e');
      return [];
    }
  }
}