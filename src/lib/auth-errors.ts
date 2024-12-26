// Map of error codes to user-friendly messages
export const AUTH_ERROR_MESSAGES: Record<string, string> = {
  'invalid_credentials': 'The email or password you entered is incorrect',
  'email_not_confirmed': 'Please verify your email address',
  'user_not_found': 'No account found with this email',
  'invalid_grant': 'Invalid login credentials',
  'default': 'An error occurred during sign in'
};

export function getAuthErrorMessage(error: any): string {
  if (!error) return AUTH_ERROR_MESSAGES.default;
  
  const code = error.code || error.message;
  return AUTH_ERROR_MESSAGES[code] || error.message || AUTH_ERROR_MESSAGES.default;
}