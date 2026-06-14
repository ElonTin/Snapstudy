namespace SnapStudy.Api.Models;

public sealed class SendPushRequest
{
    public string Title { get; set; } = "SNAPSTUDY";
    public string Body { get; set; } = string.Empty;
    public string Type { get; set; } = "push";
    public string? FcmToken { get; set; }
    public string? UserId { get; set; }
}
