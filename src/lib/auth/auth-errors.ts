// Map of error codes to user-friendly messages
export const AUTH_ERROR_MESSAGES: Record<string, string> = {
  'invalid_credentials': 'The email or password you entered is incorrect',
  'email_not_confirmed': 'Please verify your email address',
  'user_not_found': 'No account found with this email',
  'invalid_grant': 'Invalid login credentials',
  'email_taken': 'An account with this email already exists',
  'weak_password': 'Password must be at least 8 characters long',
  'profile_not_found': 'User profile not found',
  'account_disabled': 'This account has been deactivated',
  'invalid_api_key': 'Unable to connect to authentication service',
  'default': 'An error occurred during authentication'
};

export function getAuthErrorMessage(error: any): string {
  if (!error) return AUTH_ERROR_MESSAGES.default;
  
  // Log the full error for debugging
  console.debug('Auth error details:', error);
  
  // Check for API key errors
  if (error.message?.includes('Invalid API key')) {
    return AUTH_ERROR_MESSAGES.invalid_api_key;
  }
  
  const code = error.code || error.message;
  return AUTH_ERROR_MESSAGES[code] || error.message || AUTH_ERROR_MESSAGES.default;
}