using backend.Models;

namespace backend.Tests;

public class UserModelTests
{
    [Fact]
    public void User_CanBeCreated_WithValidProperties()
    {
        // Arrange & Act
        var user = new User
        {
            Id = 1,
            Username = "testuser",
            Email = "test@example.com",
            CreatedAt = DateTime.UtcNow
        };

        // Assert
        Assert.Equal(1, user.Id);
        Assert.Equal("testuser", user.Username);
        Assert.Equal("test@example.com", user.Email);
        Assert.NotEqual(default(DateTime), user.CreatedAt);
    }

    [Fact]
    public void User_Username_CanBeSet()
    {
        // Arrange
        var user = new User();

        // Act
        user.Username = "newuser";

        // Assert
        Assert.Equal("newuser", user.Username);
    }
}
