//
//  DatabaseServiceBlueprint.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 14.03.2026..
//
//  INSTRUCTIONS:
//  1. Rename this file to 'DatabaseService.swift'
//  2. Replace the placeholders below with actual Project URL and Anon Key
//  3. DatabaseService.swift is already in .gitignore and will not be tracked

import Foundation
import Supabase

/// Configuration constants for the Supabase client.
/// You can find these in your Supabase Settings.
enum SupabaseConfig {
    static let projectURL = URL(string: "SUPABASE_PROJECT_URL")!
    static let anonKey = "SUPABASE_ANON_KEY"
}

/// The global Supabase client instance used throughout the app.
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.projectURL,
    supabaseKey: SupabaseConfig.anonKey
)

// PRO-TIP:
// If you are building a larger app, consider wrapping the 'supabase'
// client in a class or actor to handle specific database queries:
// DatabaseService.shared.fetchTracks()
