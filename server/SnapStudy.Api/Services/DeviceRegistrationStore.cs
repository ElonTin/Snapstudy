using System.Text.Json;
using SnapStudy.Api.Models;

namespace SnapStudy.Api.Services;

public sealed class DeviceRegistrationStore
{
    private readonly string _filePath;
    private readonly SemaphoreSlim _gate = new(1, 1);
    private readonly JsonSerializerOptions _json = new() { WriteIndented = true };

    public DeviceRegistrationStore(IConfiguration configuration)
    {
        _filePath = configuration["DeviceStore:FilePath"] ?? "data/device-registrations.json";
    }

    public async Task<DeviceRegistration> UpsertAsync(RegisterDeviceRequest request)
    {
        await _gate.WaitAsync();
        try
        {
            var all = await ReadAllAsync();
            var now = DateTimeOffset.UtcNow;
            var existing = all.FirstOrDefault(d => d.FcmToken == request.FcmToken);

            if (existing is null)
            {
                existing = new DeviceRegistration
                {
                    FcmToken = request.FcmToken,
                    Platform = request.Platform,
                    UserId = request.UserId,
                    RegisteredAt = now,
                    UpdatedAt = now,
                };
                all.Add(existing);
            }
            else
            {
                existing.Platform = request.Platform;
                existing.UserId = request.UserId ?? existing.UserId;
                existing.UpdatedAt = now;
            }

            await WriteAllAsync(all);
            return existing;
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<IReadOnlyList<DeviceRegistration>> ListAsync()
    {
        await _gate.WaitAsync();
        try
        {
            return await ReadAllAsync();
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<List<DeviceRegistration>> ReadAllAsync()
    {
        if (!File.Exists(_filePath))
        {
            return [];
        }

        await using var stream = File.OpenRead(_filePath);
        var items = await JsonSerializer.DeserializeAsync<List<DeviceRegistration>>(stream, _json);
        return items ?? [];
    }

    private async Task WriteAllAsync(List<DeviceRegistration> items)
    {
        var directory = Path.GetDirectoryName(_filePath);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        await using var stream = File.Create(_filePath);
        await JsonSerializer.SerializeAsync(stream, items, _json);
    }
}
