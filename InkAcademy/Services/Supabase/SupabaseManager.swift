import Foundation
import Supabase

/// Central Supabase client – single source of truth.
/// Replace the placeholder values with your own project credentials
/// from https://supabase.com/dashboard → Settings → API.
enum SupabaseManager {
    // MARK: - Configuration

    /// Your Supabase project URL  (e.g. "https://xyzcompany.supabase.co")
    private static let projectURL = URL(string: "https://zmnbzmltemejqmgvbwou.supabase.co")!

    /// Your **anon / public** key  (safe to embed in client apps)
    private static let anonKey = "sb_publishable_Ej2uzr54nnCenw7VwDoMYQ_kQUaBEDb"

    // MARK: - Shared Client

    static let client = SupabaseClient(
        supabaseURL: projectURL,
        supabaseKey: anonKey
    )
}
