#define WTHTTP_CONFIGURATION "../wt_config.xml"

#include "000_Server/Server.h"
#include "001_App/App.h"
#include <Wt/WSslInfo.h>
#include <Wt/WLogger.h>
#include <csignal>
#include <memory>

#include <Wt/Auth/AuthService.h>
#include <Wt/Auth/HashFunction.h>
#include <Wt/Auth/PasswordService.h>
#include <Wt/Auth/PasswordStrengthValidator.h>
#include <Wt/Auth/PasswordVerifier.h>
#include <Wt/Auth/GoogleService.h>
#include <Wt/Auth/FacebookService.h>
#include <Wt/Auth/Mfa/TotpProcess.h>

// Define static members
Wt::Auth::AuthService Server::authService;
Wt::Auth::PasswordService Server::passwordService(Server::authService);
std::vector<std::unique_ptr<Wt::Auth::OAuthService>> Server::oAuthServices;

Server::Server(int argc, char **argv)
    : Wt::WServer(argc, argv),
      argc_(argc),
      argv_(argv)
{
    setServerConfiguration(argc_, argv_, WTHTTP_CONFIGURATION);
    configureAuth();

    addEntryPoint(
        Wt::EntryPointType::Application,
        [](const Wt::WEnvironment& env) {
            return std::make_unique<App>(env);
        },
        "/");

    // run();
}

int Server::run()
{
 
   
    try {
        if (start()) {
            int sig = WServer::waitForShutdown();
            
            Wt::log("info") << "Shutdown (signal = " << sig << ")";
            stop();

            if (sig == SIGHUP)
                restart(argc_, argv_, environ);
        }
    } catch (WServer::Exception& e) {
        Wt::log("error") << e.what();
        return 1;
    } catch (std::exception& e) {
        Wt::log("error") << "exception: " << e.what();
        return 1;
    }
    return 0;
}

void Server::configureAuth()
{
    authService.setAuthTokensEnabled(true, "logincookie");
    authService.setEmailVerificationEnabled(false);
    authService.setEmailVerificationRequired(false);
    authService.setIdentityPolicy(Wt::Auth::IdentityPolicy::LoginName);
    
    // authService.setMfaProvider(Wt::Auth::Identity::MultiFactor);
    // authService.setMfaRequired(true);
    // authService.setMfaThrottleEnabled(true);

    auto verifier = std::make_unique<Wt::Auth::PasswordVerifier>();
    verifier->addHashFunction(std::make_unique<Wt::Auth::BCryptHashFunction>(12));
    passwordService.setVerifier(std::move(verifier));
    passwordService.setPasswordThrottle(std::make_unique<Wt::Auth::AuthThrottle>());
    passwordService.setStrengthValidator(std::make_unique<Wt::Auth::PasswordStrengthValidator>());

    // if (Wt::Auth::GoogleService::configured()) {
    //     oAuthServices.push_back(std::make_unique<Wt::Auth::GoogleService>(authService));
    // }
    // if (Wt::Auth::FacebookService::configured()) {
    //     oAuthServices.push_back(std::make_unique<Wt::Auth::FacebookService>(authService));
    // }
    for (const auto& oAuthService : oAuthServices) {
        oAuthService->generateRedirectEndpoint();
    }
}
