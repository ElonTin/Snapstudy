namespace SnapStudy.Api.Models;

public sealed class DeviceRegistration
{
    public string FcmToken { get; set; } = string.Empty;
    public string Platform { get; set; } = "unknown";
    public string? UserId { get; set; }
    public DateTimeOffset RegisteredAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
