
public enum AuthChangeEvent: String {
    case signedIn = "SIGNED_IN"
    case signedOut = "SIGNED_OUT"
    case userUpdated = "USER_UPDATED"
    case userDeleted = "USER_DELETED"
    case passwordRecovery = "PASSWORD_RECOVERY"
}
