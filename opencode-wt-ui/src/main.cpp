#include "000_Server/Server.h"
#include "001_App/App.h"
#include <Wt/WLogger.h>

int main(int argc, char **argv)
{
    Wt::log("info") << "Starting Wt server...";

    Server server(argc, argv);

    server.run();

    return 0;
}