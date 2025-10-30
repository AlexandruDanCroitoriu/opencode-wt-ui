#include "002_Dbo/Session.h"
#include "002_Dbo/Tables/Permission.h"
#include "000_Server/Server.h"

#include <Wt/Dbo/SqlConnection.h>
#include <Wt/Dbo/backend/Sqlite3.h>
#include <Wt/Dbo/backend/Postgres.h>
#include <Wt/Auth/Identity.h>
#include <Wt/Auth/PasswordService.h>


#include <cstdlib>
#include <memory>
#include <stdexcept>


Session::Session(const std::string &sqliteDb)
{
  std::unique_ptr<Wt::Dbo::SqlConnection> connection;

  #ifdef DEBUG
  // Debug mode - use SQLite
  auto sqliteConnection = std::make_unique<Wt::Dbo::backend::Sqlite3>(sqliteDb);
  sqliteConnection->setProperty("show-queries", "true");
  Wt::log("info") << "Using SQLite database in debug mode";
  connection = std::move(sqliteConnection);
  #else
  // Production mode - use PostgreSQL
  const char *postgresHost = std::getenv("POSTGRES_HOST");
  if (!postgresHost) {
    throw std::runtime_error("POSTGRES_HOST environment variable is not set");
  }

  const char *postgresPort = std::getenv("POSTGRES_PORT");
  if (!postgresPort) {
    throw std::runtime_error("POSTGRES_PORT environment variable is not set");
  }

  const char *postgresDatabase = std::getenv("POSTGRES_DBNAME");
  if (!postgresDatabase) {
    throw std::runtime_error("POSTGRES_DBNAME environment variable is not set");
  }

  const char *postgresUser = std::getenv("POSTGRES_USER");
  if (!postgresUser) {
    throw std::runtime_error("POSTGRES_USER environment variable is not set");
  }

  const char *postgresPassword = std::getenv("POSTGRES_PASSWORD");
  if (!postgresPassword) {
    throw std::runtime_error("POSTGRES_PASSWORD environment variable is not set");
  }

  std::string postgresConnectionString = "host=" + std::string(postgresHost) +
                  " port=" + std::string(postgresPort) +
                  " dbname=" + std::string(postgresDatabase) +
                  " user=" + std::string(postgresUser) +
                  " password=" + std::string(postgresPassword);

  auto postgresConnection = std::make_unique<Wt::Dbo::backend::Postgres>(postgresConnectionString.c_str());
  Wt::log("info") << "Using PostgreSQL database in production mode";
  connection = std::move(postgresConnection);
  #endif

  if (!connection) {
    throw std::runtime_error("Database connection was not initialised");
  }

  setConnection(std::move(connection));

  mapClass<User>("user");
  mapClass<Permission>("permission");
  mapClass<AuthInfo>("auth_info");
  mapClass<AuthInfo::AuthIdentityType>("auth_identity");
  mapClass<AuthInfo::AuthTokenType>("auth_token");

  try {
    if (!created_) {
      createTables();
      created_ = true;
      Wt::log("info") << "Created database.";
    } else {
      Wt::log("info") << "Using existing database";
    }
  } catch (Wt::Dbo::Exception& e) {
    Wt::log("info") << "Using existing database";
  }
  users_ = std::make_unique<UserDatabase>(*this);
  createInitialData();

}


Wt::Auth::AbstractUserDatabase& Session::users()
{
  return *users_;
}

dbo::ptr<User> Session::user() const
{
  if (login_.loggedIn()) {
    dbo::ptr<AuthInfo> authInfo = users_->find(login_.user());
    return authInfo->user();
  } else
    return dbo::ptr<User>();
}

dbo::ptr<User> Session::user(const Wt::Auth::User& authUser)
{
  dbo::ptr<AuthInfo> authInfo = users_->find(authUser);

  dbo::ptr<User> user = authInfo->user();

  if (!user) {
    user = add(std::make_unique<User>());
    authInfo.modify()->setUser(user);
  }

  return user;
}

const Wt::Auth::AuthService& Session::auth()
{
  return Server::authService;
}

const Wt::Auth::PasswordService& Session::passwordAuth()
{
  return Server::passwordService;
}

std::vector<const Wt::Auth::OAuthService *> Session::oAuth()
{
  std::vector<const Wt::Auth::OAuthService *> result;
  result.reserve(Server::oAuthServices.size());
  for (const auto& auth : Server::oAuthServices) {
    result.push_back(auth.get());
  }
  return result;
}

Wt::Dbo::ptr<User> addUser(Wt::Dbo::Session& session, UserDatabase& users, const std::string& loginName,
             const std::string& email, const std::string& password)
{
  Wt::Dbo::Transaction t(session);
  auto user = session.addNew<User>(loginName);
  auto authUser = users.registerNew();
  authUser.addIdentity(Wt::Auth::Identity::LoginName, loginName);
  authUser.setEmail(email);
  Server::passwordService.updatePassword(authUser, password);

  // Link User and auth user
  Wt::Dbo::ptr<AuthInfo> authInfo = session.find<AuthInfo>("where id = ?").bind(authUser.id());
  authInfo.modify()->setUser(user);

  t.commit();
  return user;
}

void Session::createInitialData()
{
  // Create STYLUS permission if it doesn't exist
  {
    Wt::Dbo::Transaction t(*this);
    
    Wt::Dbo::ptr<Permission> stylusPermission = find<Permission>()
      .where("name = ?")
      .bind("STYLUS");
    
    if (!stylusPermission) {
      stylusPermission = add(std::make_unique<Permission>("STYLUS"));
      Wt::log("info") << "Created STYLUS permission.";
    }
    
    t.commit();
  }
  
  // Check if admin user already exists by querying auth_identity table
  {
    Wt::Dbo::Transaction t(*this);
    
    Wt::Dbo::ptr<AuthInfo::AuthIdentityType> existingIdentity = 
      find<AuthInfo::AuthIdentityType>()
      .where("provider = ? AND identity = ?")
      .bind(Wt::Auth::Identity::LoginName)
      .bind("maxuli");
    
    if (existingIdentity) {
      Wt::log("info") << "Admin user 'maxuli' already exists, skipping creation.";
      t.commit();
      return;
    }
    
    t.commit();
  }
  
  // Create admin user using the authentication framework
  Wt::Dbo::ptr<User> adminUser = addUser(*this, *users_, "maxuli", "maxuli@example.com", "asdfghj1");
  
  // Assign STYLUS permission to admin user
  {
    Wt::Dbo::Transaction t(*this);
    
    // Reload the permission within this transaction
    Wt::Dbo::ptr<Permission> stylusPermission = find<Permission>()
      .where("name = ?")
      .bind("STYLUS");
    
    adminUser.modify()->permissions_.insert(stylusPermission);
    t.commit();
  }
  
  Wt::log("info") << "Created admin user 'maxuli' with STYLUS permission.";
}



