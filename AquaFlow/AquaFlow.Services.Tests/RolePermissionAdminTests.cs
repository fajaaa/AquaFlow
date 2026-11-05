using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class RolePermissionAdminTests
{
    // Roles: 1 = Admin (system), 2 = Custom (regular). Permissions: 1 = Roles.Manage (system), 2 = Custom.Perm (regular),
    // 3 = Custom.Other (regular, unassigned). Assignments: Admin->Roles.Manage (id 1), Custom->Custom.Perm (id 2).
    private static async Task<AquaFlowDbContext> CreateContextAsync()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        var context = new AquaFlowDbContext(options);
        context.UserRoles.AddRange(
            new UserRole { Id = 1, Name = "Admin", IsSystem = true },
            new UserRole { Id = 2, Name = "Custom" });
        context.Permissions.AddRange(
            new Permission { Id = 1, Code = "Roles.Manage", Name = "Manage roles", Module = "Roles", IsSystem = true },
            new Permission { Id = 2, Code = "Custom.Perm", Name = "Custom perm", Module = "Custom" },
            new Permission { Id = 3, Code = "Custom.Other", Name = "Other perm", Module = "Other" });
        context.UserRolePermissions.AddRange(
            new UserRolePermission { Id = 1, UserRoleId = 1, PermissionId = 1 },
            new UserRolePermission { Id = 2, UserRoleId = 2, PermissionId = 2 });
        await context.SaveChangesAsync();
        return context;
    }

    private static IMapper CreateMapper()
    {
        var config = new TypeAdapterConfig();
        config.NewConfig<UserRolePatchRequest, UserRole>().IgnoreNullValues(true);
        config.NewConfig<PermissionPatchRequest, Permission>().IgnoreNullValues(true);
        config.NewConfig<UserRolePermissionPatchRequest, UserRolePermission>().IgnoreNullValues(true);
        return new Mapper(config);
    }

    private static UserRoleService RoleService(AquaFlowDbContext context) => new(
        context, CreateMapper(),
        new IValidator<UserRoleInsertRequest>[] { new UserRoleInsertValidator() },
        new IValidator<UserRoleUpdateRequest>[] { new UserRoleUpdateValidator() },
        new IValidator<UserRolePatchRequest>[] { new UserRolePatchValidator() });

    private static PermissionService PermissionSvc(AquaFlowDbContext context) => new(
        context, TestSecurityStamps.Create(context), CreateMapper(),
        new IValidator<PermissionInsertRequest>[] { new PermissionInsertValidator() },
        new IValidator<PermissionUpdateRequest>[] { new PermissionUpdateValidator() },
        new IValidator<PermissionPatchRequest>[] { new PermissionPatchValidator() });

    private static UserRolePermissionService AssignmentService(AquaFlowDbContext context) => new(
        context, TestSecurityStamps.Create(context), CreateMapper(),
        new IValidator<UserRolePermissionInsertRequest>[] { new UserRolePermissionInsertValidator() },
        new IValidator<UserRolePermissionUpdateRequest>[] { new UserRolePermissionUpdateValidator() },
        new IValidator<UserRolePermissionPatchRequest>[] { new UserRolePermissionPatchValidator() });

    private static User NewUser(int roleId) => new()
    {
        Id = 1,
        Email = "u@x.com",
        PasswordHash = "h",
        PasswordSalt = "s",
        UserRoleId = roleId,
        IsActive = true,
        SecurityStamp = "old"
    };

    // ---- UserRole ----

    [Fact]
    public async Task Role_Insert_NeverCreatesSystemRole()
    {
        await using var context = await CreateContextAsync();

        var response = await RoleService(context).InsertAsync(new UserRoleInsertRequest { Name = "Auditor" });

        Assert.False(response.IsSystem);
        Assert.False((await context.UserRoles.SingleAsync(r => r.Name == "Auditor")).IsSystem);
    }

    [Fact]
    public async Task Role_Update_ClientCannotChangeIsSystem()
    {
        await using var context = await CreateContextAsync();

        var custom = await RoleService(context).UpdateAsync(2, new UserRoleUpdateRequest { Name = "Custom", Description = "x" });
        var admin = await RoleService(context).UpdateAsync(1, new UserRoleUpdateRequest { Name = "Admin", Description = "x" });

        Assert.False(custom.IsSystem);
        Assert.True(admin.IsSystem);
    }

    [Fact]
    public async Task Role_SystemRole_NameChange_Throws()
    {
        await using var context = await CreateContextAsync();

        await Assert.ThrowsAsync<ClientException>(() =>
            RoleService(context).UpdateAsync(1, new UserRoleUpdateRequest { Name = "Root" }));
        await Assert.ThrowsAsync<ClientException>(() =>
            RoleService(context).PatchAsync(1, new UserRolePatchRequest { Name = "Root" }));
    }

    [Fact]
    public async Task Role_SystemRole_Deactivate_Throws()
    {
        await using var context = await CreateContextAsync();

        await Assert.ThrowsAsync<ClientException>(() =>
            RoleService(context).UpdateAsync(1, new UserRoleUpdateRequest { Name = "Admin", IsActive = false }));
        await Assert.ThrowsAsync<ClientException>(() =>
            RoleService(context).PatchAsync(1, new UserRolePatchRequest { IsActive = false }));
    }

    [Fact]
    public async Task Role_SystemRole_Delete_Throws()
    {
        await using var context = await CreateContextAsync();

        await Assert.ThrowsAsync<ClientException>(() => RoleService(context).DeleteAsync(1));
        Assert.True(await context.UserRoles.AnyAsync(r => r.Id == 1));
    }

    [Fact]
    public async Task Role_Delete_WithUsers_Throws()
    {
        await using var context = await CreateContextAsync();
        context.Users.Add(NewUser(2));
        await context.SaveChangesAsync();

        await Assert.ThrowsAsync<ClientException>(() => RoleService(context).DeleteAsync(2));
        Assert.True(await context.UserRoles.AnyAsync(r => r.Id == 2));
    }

    [Fact]
    public async Task Role_Delete_UnusedNonSystem_Succeeds()
    {
        await using var context = await CreateContextAsync();
        context.UserRolePermissions.RemoveRange(context.UserRolePermissions.Where(x => x.UserRoleId == 2));
        await context.SaveChangesAsync();

        await RoleService(context).DeleteAsync(2);

        Assert.False(await context.UserRoles.AnyAsync(r => r.Id == 2));
    }

    [Fact]
    public async Task Role_Filters_ByNameContainsAndIsActive()
    {
        await using var context = await CreateContextAsync();
        context.UserRoles.Add(new UserRole { Id = 3, Name = "Auditor", IsActive = false });
        await context.SaveChangesAsync();
        var service = RoleService(context);

        var byName = await service.GetAllAsync(new UserRoleSearchObject { Name = "ust" });
        var byActive = await service.GetAllAsync(new UserRoleSearchObject { IsActive = false });

        Assert.Equal("Custom", Assert.Single(byName.Items).Name);
        Assert.Equal("Auditor", Assert.Single(byActive.Items).Name);
    }

    // ---- Permission ----

    [Fact]
    public async Task Permission_Insert_NeverCreatesSystemPermission()
    {
        await using var context = await CreateContextAsync();

        var response = await PermissionSvc(context).InsertAsync(new PermissionInsertRequest
        {
            Code = "New.Perm", Name = "New", Module = "New", Description = "d"
        });

        Assert.False(response.IsSystem);
    }

    [Fact]
    public async Task Permission_SystemPermission_CodeChange_Throws()
    {
        await using var context = await CreateContextAsync();

        await Assert.ThrowsAsync<ClientException>(() => PermissionSvc(context).UpdateAsync(1, new PermissionUpdateRequest
        {
            Code = "Roles.Other", Name = "Manage roles", Module = "Roles", Description = "d"
        }));
        await Assert.ThrowsAsync<ClientException>(() =>
            PermissionSvc(context).PatchAsync(1, new PermissionPatchRequest { Code = "Roles.Other" }));
    }

    [Fact]
    public async Task Permission_SystemPermission_Deactivate_Throws()
    {
        await using var context = await CreateContextAsync();

        await Assert.ThrowsAsync<ClientException>(() => PermissionSvc(context).UpdateAsync(1, new PermissionUpdateRequest
        {
            Code = "Roles.Manage", Name = "Manage roles", Module = "Roles", Description = "d", IsActive = false
        }));
        await Assert.ThrowsAsync<ClientException>(() =>
            PermissionSvc(context).PatchAsync(1, new PermissionPatchRequest { IsActive = false }));
    }

    [Fact]
    public async Task Permission_SystemPermission_Delete_Throws()
    {
        await using var context = await CreateContextAsync();
        context.UserRolePermissions.RemoveRange(context.UserRolePermissions.Where(x => x.PermissionId == 1));
        await context.SaveChangesAsync();

        await Assert.ThrowsAsync<ClientException>(() => PermissionSvc(context).DeleteAsync(1));
    }

    [Fact]
    public async Task Permission_Delete_AssignedToRole_Throws()
    {
        await using var context = await CreateContextAsync();

        await Assert.ThrowsAsync<ClientException>(() => PermissionSvc(context).DeleteAsync(2));
        Assert.True(await context.Permissions.AnyAsync(p => p.Id == 2));
    }

    [Fact]
    public async Task Permission_Delete_UnassignedNonSystem_Succeeds()
    {
        await using var context = await CreateContextAsync();

        await PermissionSvc(context).DeleteAsync(3);

        Assert.False(await context.Permissions.AnyAsync(p => p.Id == 3));
    }

    [Fact]
    public async Task Permission_Filters_ByCodeNameModuleAndIsActive()
    {
        await using var context = await CreateContextAsync();
        context.Permissions.Add(new Permission { Id = 4, Code = "Hidden.Perm", Name = "Hidden", Module = "Hidden", IsActive = false });
        await context.SaveChangesAsync();
        var service = PermissionSvc(context);

        Assert.Equal("Custom.Perm", Assert.Single((await service.GetAllAsync(new PermissionSearchObject { Code = "m.Pe" })).Items).Code);
        Assert.Equal("Other perm", Assert.Single((await service.GetAllAsync(new PermissionSearchObject { Name = "Other" })).Items).Name);
        Assert.Equal("Roles.Manage", Assert.Single((await service.GetAllAsync(new PermissionSearchObject { Module = "Roles" })).Items).Code);
        Assert.Equal("Hidden.Perm", Assert.Single((await service.GetAllAsync(new PermissionSearchObject { IsActive = false })).Items).Code);
    }

    // ---- UserRolePermission ----

    [Fact]
    public async Task Assignment_Insert_Duplicate_Throws()
    {
        await using var context = await CreateContextAsync();

        await Assert.ThrowsAsync<ClientException>(() =>
            AssignmentService(context).InsertAsync(new UserRolePermissionInsertRequest { UserRoleId = 2, PermissionId = 2 }));
    }

    [Fact]
    public async Task Assignment_Delete_RolesManageFromAdmin_Throws()
    {
        await using var context = await CreateContextAsync();

        await Assert.ThrowsAsync<ClientException>(() => AssignmentService(context).DeleteAsync(1));
        Assert.True(await context.UserRolePermissions.AnyAsync(x => x.Id == 1));
    }

    [Fact]
    public async Task Assignment_Insert_And_Delete_RotateSecurityStampOfRoleUsers()
    {
        await using var context = await CreateContextAsync();
        context.Users.Add(NewUser(2));
        await context.SaveChangesAsync();
        var service = AssignmentService(context);

        var created = await service.InsertAsync(new UserRolePermissionInsertRequest { UserRoleId = 2, PermissionId = 3 });
        var stampAfterInsert = (await context.Users.AsNoTracking().SingleAsync()).SecurityStamp;
        Assert.NotEqual("old", stampAfterInsert);

        await service.DeleteAsync(created.Id);
        var stampAfterDelete = (await context.Users.AsNoTracking().SingleAsync()).SecurityStamp;
        Assert.NotEqual(stampAfterInsert, stampAfterDelete);
    }

    [Fact]
    public async Task Assignment_Filters_ByRoleAndPermission()
    {
        await using var context = await CreateContextAsync();
        var service = AssignmentService(context);

        var byRole = await service.GetAllAsync(new UserRolePermissionSearchObject { UserRoleId = 2 });
        var byPermission = await service.GetAllAsync(new UserRolePermissionSearchObject { PermissionId = 1 });

        Assert.Equal(2, Assert.Single(byRole.Items).PermissionId);
        Assert.Equal(1, Assert.Single(byPermission.Items).UserRoleId);
    }
}
