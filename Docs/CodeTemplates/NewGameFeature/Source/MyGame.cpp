// MyGame module implementation

#include "MyGame.h"

DEFINE_LOG_CATEGORY(LogMyGame);

IMPLEMENT_MODULE(FMyGameModule, MyGame);

void FMyGameModule::StartupModule()
{
    UE_LOG(LogMyGame, Log, TEXT("MyGame module started"));
}

void FMyGameModule::ShutdownModule()
{
    UE_LOG(LogMyGame, Log, TEXT("MyGame module shutdown"));
}
