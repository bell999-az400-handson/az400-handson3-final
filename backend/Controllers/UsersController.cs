using Microsoft.AspNetCore.Mvc;
using Microsoft.ApplicationInsights;
using backend.Models;
using backend.Data;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly UserDbContext _context;
    private readonly TelemetryClient _telemetryClient;
    private readonly ILogger<UsersController> _logger;

    public UsersController(UserDbContext context, TelemetryClient telemetryClient, ILogger<UsersController> logger)
    {
        _context = context;
        _telemetryClient = telemetryClient;
        _logger = logger;
    }

[HttpGet]
public ActionResult<IEnumerable<User>> GetUsers(
    [FromQuery] int page = 1, 
    [FromQuery] int pageSize = 10)
{
    _telemetryClient.TrackEvent("GetUsers", new Dictionary<string, string>
    {
        { "Page", page.ToString() },
        { "PageSize", pageSize.ToString() }
    });

    var users = _context.Users
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .ToList();

    _logger.LogInformation("Retrieved {Count} users (Page {Page}, PageSize {PageSize})", 
        users.Count, page, pageSize);

    return Ok(users);
}

    [HttpGet("{id}")]
    public ActionResult<User> GetUser(int id)
    {
        _telemetryClient.TrackEvent("GetUser", new Dictionary<string, string> { { "UserId", id.ToString() } });
        _logger.LogInformation("Getting user with ID {UserId}", id);

        var user = _context.Users.Find(id);
        if (user == null)
        {
            _logger.LogWarning("User with ID {UserId} not found", id);
            return NotFound();
        }

        return Ok(user);
    }

    [HttpPost]
    public ActionResult<User> CreateUser(User user)
    {
        _telemetryClient.TrackEvent("CreateUser");
        _logger.LogInformation("Creating new user: {Username}", user.Username);

        _context.Users.Add(user);
        _context.SaveChanges();

        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
    }
}
