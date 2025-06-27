import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Import compute function
import 'dart:convert'; // Import for json.decode

import '../../../../core/errors/exceptions.dart'; // Ensure these custom exceptions are defined
import '../../../../core/constants/api_constants.dart';
import '../models/visit_model.dart';
import '../utils/visit_parser_utils.dart'; // Import our new utility file

abstract class VisitRemoteDataSource {
  Future<List<VisitModel>> getAllVisits();
  Future<VisitModel> addVisit(VisitModel visit);
}

class VisitRemoteDataSourceImpl implements VisitRemoteDataSource {
  final Dio client;
  // Your Supabase API Key. It's recommended to load this from environment
  // variables or a secure configuration for production.
  final String _supabaseApiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxZ2JmdHdzb2RwdHRwcWdxbmJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5ODk5OTksImV4cCI6MjA2MTU2NTk5OX0.rwJSY4bJaNdB8jDn3YJJu_gKtznzm-dUKQb4OvRtP6c';


  VisitRemoteDataSourceImpl({required this.client});

  @override
  Future<List<VisitModel>> getAllVisits() async {
    try {
      final response = await client.get(
        ApiConstants.visitsEndpoint,
        options: Options(
          responseType: ResponseType.plain, // Request raw response text
          headers: {
            'apikey': _supabaseApiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final String rawJsonString = response.data.toString();

        final String cleanedJsonString = _cleanSupabaseVisitsJson(rawJsonString);

        // Attempt to parse the cleaned string
        final List<dynamic> visitsJson = json.decode(cleanedJsonString);

        // Offload parsing of the list to an Isolate
        return compute(parseVisitsList, visitsJson);
      } else {
        throw ServerException(message: 'Failed to load visits. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
        throw NetworkException(message: 'No internet connection or server unreachable.');
      } else if (e.response != null) {
        print('Server error response data: ${e.response?.data}');
        throw ServerException(
          message: e.response?.data['message'] ?? 'Server error: ${e.response?.statusCode}',
        );
      } else {
        throw ServerException(message: 'An unexpected Dio error occurred: ${e.message}');
      }
    } on FormatException catch (e) {
      // This is the error we're trying to fix with the cleaning function.
      print('*** Data Parsing Error (FormatException) in VisitRemoteDataSourceImpl ***');
      print('Error message: ${e.message}');
      // Log a snippet of the problematic JSON source for debugging
      print('Problematic JSON snippet (source, up to 500 chars): "${e.source?.substring(0, (e.source!.length > 500 ? 500 : e.source!.length))}"...');
      throw DataParsingException(message: 'Failed to parse visit data due to malformed JSON: ${e.message}');
    } catch (e, stackTrace) {
      print('*** An unknown error occurred in VisitRemoteDataSourceImpl ***');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      throw ServerException(message: 'An unknown error occurred: ${e.toString()}');
    }
  }

  @override
  Future<VisitModel> addVisit(VisitModel visit) async {
    // This method is for POST and typically receives well-formed JSON,
    // so no extensive JSON cleaning is usually required here.
    try {
      final response = await client.post(
        ApiConstants.visitsEndpoint,
        data: visit.toNewVisitJson(),
        queryParameters: {'select': '*'},
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'apikey': _supabaseApiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      // --- ADD THESE PRINT STATEMENTS FOR DEBUGGING ---
      print('*** Add Visit Response Status Code: ${response.statusCode} ***');
      print('*** Add Visit Response Data Type: ${response.data.runtimeType} ***');
      print('*** Add Visit Response Data: ${response.data} ***');
      // --- END ADDED PRINT STATEMENTS ---

      if (response.statusCode == 201) {
        // We need to be careful with the type of response.data[0] here too,
        // as it might be _Map<dynamic, dynamic>
        if (response.data is String && (response.data as String).isEmpty) {
          print('Warning: Supabase returned 201 but with an empty response body. Assuming success and returning original visit for now.');
          // Temporarily return the passed-in visit. The cubit will re-fetch all.
          // This ensures the Future<VisitModel> signature is satisfied.
          return visit;
        }

        if (response.data is List && response.data.isNotEmpty) {
          final dynamic rawNewVisitData = response.data[0];
          if (rawNewVisitData is Map) {
            // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
            // before passing to parseSingleVisit (which expects Map<String, dynamic>)
            final Map<String, dynamic> stringKeyedMap = rawNewVisitData.map(
                  (key, value) => MapEntry(key.toString(), value),
            );
            return compute(parseSingleVisit, stringKeyedMap);
          } else {
            throw ServerException(message: 'Response data item is not a map: ${rawNewVisitData.runtimeType}.');
          }
        }
        throw ServerException(message: 'Failed to parse new visit response: Response data is not a valid non-empty list.');
      } else {
        throw ServerException(message: 'Failed to add visit. Status code: ${response.statusCode}. Response: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
        throw NetworkException(message: 'No internet connection or server unreachable.');
      } else if (e.response != null) {
        print('Server error response data (Add Visit): ${e.response?.data}'); // Log server error data
        throw ServerException(
          message: e.response?.data['message'] ?? 'Server error: ${e.response?.statusCode}',
        );
      } else {
        throw ServerException(message: 'An unexpected Dio error occurred (Add Visit): ${e.message}');
      }
    } on FormatException catch (e) {
      print('*** Data Parsing Error (FormatException) in VisitRemoteDataSourceImpl.addVisit ***');
      print('Error message: ${e.message}');
      throw DataParsingException(message: 'Failed to parse add visit response data due to malformed JSON: ${e.message}');
    } catch (e, stackTrace) {
      print('*** An unknown error occurred in VisitRemoteDataSourceImpl.addVisit ***');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      throw ServerException(message: 'An unknown error occurred while adding visit: ${e.toString()}');
    }
  }

  /// **Utility function to clean the malformed JSON string from Supabase.**
  /// This function is a workaround for known data inconsistencies.
  /// It addresses log prefixes, specific extraneous lines, and issues within the 'notes' field,
  /// as well as ensuring the overall JSON array structure is valid.
  String _cleanSupabaseVisitsJson(String rawJson) {
    print('--- Original Raw JSON String (for cleaning debug) ---');
    // Print a truncated version for readability in console logs
    print(rawJson.substring(0, (rawJson.length > 1000 ? 1000 : rawJson.length)) + (rawJson.length > 1000 ? '\n...' : ''));
    print('...');

    String cleaned = rawJson;

    // Step 1: Remove common Flutter log prefixes at the start of lines
    cleaned = cleaned.replaceAll(RegExp(r'^I/flutter \(\d+\):\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^D/View\s+\(\s*\d+\):\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^I/Choreographer\(\d+\):\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^D/ProfileInstaller\(\d+\):\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^I/PswFrameworkFactoryImpl\(\d+\):\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^I/sits_tracker_v\(\d+\):\s*', multiLine: true), '');

    // Step 2: Remove specific non-JSON lines identified in your logs that break the structure
    // We are now being more specific with the regex to ensure we don't accidentally remove valid data.
    cleaned = cleaned.replaceAll(RegExp(r'^\s*-\s*Dwights Security Tips.*$', multiLine: true), '');
        cleaned = cleaned.replaceAll(RegExp(r'^\s*-\s*Surprise birthday party.*$', multiLine: true), '');
    // These patterns target the specific "run into some few issues..." and "So give us a few days..."
    // that were appearing as separate lines or within the notes field.
    cleaned = cleaned.replaceAll(RegExp(r'^\s*run into some few issues but we managed to solve on time.*$', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*So give us a few days.*$', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*Test Locatio\s*$', multiLine: true), '');

    // Step 3: Robustly handle the 'notes' field content.
    // This regex attempts to find 'notes: "...' patterns and ensures:
    // 1. It is properly quoted.
    // 2. Any internal newlines are escaped (\n -> \\n).
    // 3. Any internal unescaped quotes are escaped ( " -> \" ).
    // It captures the content between "notes":" and the next valid JSON field/object end.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(notes"\s*:\s*)([^,\]\}]*?)(,\s*"(activities_done|created_at|status|location|id|customer_id|visit_date|notes)":|})', multiLine: true),
          (Match m) {
        String prefix = m.group(1)!; // e.g., 'notes":'
        String notesContent = m.group(2)?.trim() ?? ''; // The problematic content
        String suffix = m.group(3) ?? ''; // The rest of the object or next field

        // Check if notesContent is already correctly quoted. If not, quote it.
        if (!notesContent.startsWith('"') || !notesContent.endsWith('"')) {
          // Escape existing double quotes and backslashes within the content
          notesContent = notesContent.replaceAll('"', '\\"').replaceAll('\\', '\\\\');
          // Escape newlines within the content
          notesContent = notesContent.replaceAll('\n', '\\n');
          // Wrap in quotes
          notesContent = '"$notesContent"';
        }
        return '$prefix$notesContent$suffix';
      },
    );

    // Step 4: Clean up any resulting artifact commas or array truncation issues
    cleaned = cleaned.trim();

    // Remove any trailing commas right before a closing bracket or brace.
    cleaned = cleaned.replaceAll(RegExp(r',\s*([\]}])'), '1');
    // Remove double commas
    cleaned = cleaned.replaceAll(',,', ',');
    // Remove commas right after an opening bracket or brace
    cleaned = cleaned.replaceAll('\[,', '[');
    cleaned = cleaned.replaceAll('\{,', '{');


    // Step 5: Ensure the entire response is enclosed in a valid JSON array structure.
    // This is crucial for handling truncation.
    if (!cleaned.startsWith('[')) {
      cleaned = '[' + cleaned;
    }
    if (!cleaned.endsWith(']')) {
      // Attempt to balance unclosed braces and brackets.
      // This is a heuristic and might not be perfect for highly complex or severely corrupted JSON.
      int openBraceCount = '{'.allMatches(cleaned).length;
      int closeBraceCount = '}'.allMatches(cleaned).length;
      int openBracketCount = '['.allMatches(cleaned).length;
      int closeBracketCount = ']'.allMatches(cleaned).length;

      // Add missing closing braces
      if (openBraceCount > closeBraceCount) {
        cleaned += '}' * (openBraceCount - closeBraceCount);
      }
      // Then, if the main array isn't closed, close it.
      if (openBracketCount > closeBracketCount) {
        cleaned += ']' * (openBracketCount - closeBracketCount);
      } else if (!cleaned.endsWith(']')) {
        // Last resort: if still not ending with ']', just add it.
        cleaned += ']';
      }
    }

    print('--- Cleaned JSON String (for cleaning debug) ---');
    print(cleaned.substring(0, (cleaned.length > 1000 ? 1000 : cleaned.length)) + (cleaned.length > 1000 ? '\n...' : ''));
    print('...');

    return cleaned;
  }
}