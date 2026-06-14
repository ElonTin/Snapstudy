using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

namespace SnapStudy.Api.Services;

public sealed class FcmPushService
{
    private readonly ILogger<FcmPushService> _logger;
    private readonly IConfiguration _configuration;
    private readonly string _contentRoot;
    private bool _ready;

    public FcmPushService(
        ILogger<FcmPushService> logger,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        _logger = logger;
        _configuration = configuration;
        _contentRoot = environment.ContentRootPath;
    }

    public bool IsReady => _ready;

    public void EnsureInitialized()
    {
        if (_ready || FirebaseApp.DefaultInstance != null)
        {
            _ready = true;
            return;
        }

        var path = ResolveCredentialsPath();
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
        {
            _logger.LogWarning(
                "Firebase Admin chưa cấu hình — đặt file JSON tại {Path} hoặc biến GOOGLE_APPLICATION_CREDENTIALS",
                path ?? "(null)");
            return;
        }

        FirebaseApp.Create(new AppOptions
        {
            Credential = GoogleCredential.FromFile(path),
        });
        _ready = true;
        _logger.LogInformation("Firebase Admin SDK ready ({Path})", path);
    }

    public async Task<string> SendAsync(
        string fcmToken,
        string title,
        string body,
        string type,
        CancellationToken cancellationToken = default)
    {
        EnsureInitialized();
        if (!_ready)
        {
            throw new InvalidOperationException(
                "Firebase Admin chưa sẵn sàng — thêm secrets/firebase-service-account.json");
        }

        var message = new Message
        {
            Token = fcmToken,
            Notification = new Notification
            {
                Title = title,
                Body = body,
            },
            Data = new Dictionary<string, string>
            {
                ["type"] = type,
            },
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    ChannelId = "snapstudy_push",
                },
            },
        };

        return await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);
    }

    private string? ResolveCredentialsPath()
    {
        var envPath = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");
        if (!string.IsNullOrWhiteSpace(envPath))
        {
            return envPath;
        }

        var configured = _configuration["Firebase:CredentialsPath"];
        if (string.IsNullOrWhiteSpace(configured))
        {
            return null;
        }

        return Path.IsPathRooted(configured)
            ? configured
            : Path.Combine(_contentRoot, configured);
    }
}
