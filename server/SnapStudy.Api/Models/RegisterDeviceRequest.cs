namespace SnapStudy.Api.Models;

public sealed class RegisterDeviceRequest
{
    public string FcmToken { get; set; } = string.Empty;
    public string Platform { get; set; } = "unknown";
    public string? UserId { get; set; }
}
