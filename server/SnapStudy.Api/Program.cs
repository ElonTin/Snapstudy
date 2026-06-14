using SnapStudy.Api.Models;
using SnapStudy.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<DeviceRegistrationStore>();
builder.Services.AddSingleton<FcmPushService>();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin());
});

var app = builder.Build();

app.UseCors();

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "SnapStudy.Api" }));

app.MapPost("/api/notifications/devices", async (
    RegisterDeviceRequest request,
    DeviceRegistrationStore store,
    ILogger<Program> logger) =>
{
    if (string.IsNullOrWhiteSpace(request.FcmToken))
    {
        return Results.BadRequest(new { error = "fcmToken is required" });
    }

    var platform = string.IsNullOrWhiteSpace(request.Platform)
        ? "unknown"
        : request.Platform.Trim().ToLowerInvariant();

    var saved = await store.UpsertAsync(new RegisterDeviceRequest
    {
        FcmToken = request.FcmToken.Trim(),
        Platform = platform,
        UserId = string.IsNullOrWhiteSpace(request.UserId) ? null : request.UserId.Trim(),
    });

    logger.LogInformation(
        "Registered device {Platform} user={UserId} token={TokenPrefix}...",
        saved.Platform,
        saved.UserId ?? "(anonymous)",
        saved.FcmToken.Length > 12 ? saved.FcmToken[..12] : saved.FcmToken);

    return Results.Created("/api/notifications/devices", new
    {
        saved.Platform,
        saved.UserId,
        saved.RegisteredAt,
        saved.UpdatedAt,
    });
});

app.MapGet("/api/notifications/devices", async (DeviceRegistrationStore store) =>
{
    var items = await store.ListAsync();
    return Results.Ok(items.Select(d => new
    {
        d.Platform,
        d.UserId,
        tokenPreview = d.FcmToken.Length > 16
            ? $"{d.FcmToken[..8]}...{d.FcmToken[^6..]}"
            : d.FcmToken,
        d.RegisteredAt,
        d.UpdatedAt,
    }));
});

app.MapPost("/api/notifications/send", async (
    SendPushRequest request,
    DeviceRegistrationStore store,
    FcmPushService fcm,
    ILogger<Program> logger,
    CancellationToken cancellationToken) =>
{
    if (string.IsNullOrWhiteSpace(request.Body))
    {
        return Results.BadRequest(new { error = "body is required" });
    }

    var title = string.IsNullOrWhiteSpace(request.Title) ? "SNAPSTUDY" : request.Title.Trim();
    var type = string.IsNullOrWhiteSpace(request.Type) ? "push" : request.Type.Trim().ToLowerInvariant();

    IReadOnlyList<DeviceRegistration> targets;
    if (!string.IsNullOrWhiteSpace(request.FcmToken))
    {
        targets =
        [
            new DeviceRegistration
            {
                FcmToken = request.FcmToken.Trim(),
                Platform = "direct",
            },
        ];
    }
    else
    {
        var all = await store.ListAsync();
        targets = string.IsNullOrWhiteSpace(request.UserId)
            ? all
            : all.Where(d => d.UserId == request.UserId.Trim()).ToList();
    }

    if (targets.Count == 0)
    {
        return Results.NotFound(new { error = "No registered devices found" });
    }

    var sent = new List<object>();
    var failed = new List<object>();

    foreach (var device in targets)
    {
        try
        {
            var messageId = await fcm.SendAsync(
                device.FcmToken,
                title,
                request.Body.Trim(),
                type,
                cancellationToken);
            sent.Add(new { device.Platform, device.UserId, messageId });
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "FCM send failed for token prefix {Prefix}",
                device.FcmToken.Length > 8 ? device.FcmToken[..8] : device.FcmToken);
            failed.Add(new { device.Platform, device.UserId, error = ex.Message });
        }
    }

    return Results.Ok(new
    {
        sentCount = sent.Count,
        failedCount = failed.Count,
        sent,
        failed,
    });
});

app.Run();
