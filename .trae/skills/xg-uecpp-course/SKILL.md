---
name: "xg-uecpp-course"
description: "UE C++ course reference. Covers containers (TArray/TMap/TSet), delegates, multithreading, HTTP/WebSocket/TCP networking, smart pointers, Subsystems, GAS, Enhanced Input, Slate standalone programs, and plugin/third-party library integration. Use when user asks about UE C++, API, container selection, multithreading, or network protocols."
---

# UE C++ Development Course Reference

## Trigger Keywords

UEC++, UE C++, 虚幻C++, 虚幻开发, UECpp, TArray, TMap, TSet, delegate, FRunnable, AsyncTask, HTTP, WebSocket, TCP, Subsystem, GAS, smart pointer, UE_LOG, reflection, UCLASS, UPROPERTY, plugin development

## Skill Scope

### What this skill CAN do
- Explain UE C++ API usage, location, and design intent for any system
- Guide adding new features (container selection, async tasks, HTTP/TCP/WebSocket communication, etc.)
- Compare pros/cons of different approaches and give selection recommendations (containers, async patterns, network protocols, configuration methods)
- Provide common API code templates with file paths and line number references
- Analyze cross-system call chains (e.g., complete path from HTTP request to standalone program)
- Diagnose common development pitfalls (smart pointer circular references, TaskGraph thread pool blocking, multi-threading race conditions, etc.)

### What this skill CANNOT do
- Does NOT include actual course source code (requires course project, code root: `Courses/UE-CPP-Basic-to-Advanced/code/`)
- Does NOT cover all API details (focuses on core development practice, consult UE official docs for edge cases)
- Does NOT include Blueprint tutorials (C++ layer only)
- Does NOT include complete project deployment guides (only architectural pattern reference)

## Course Overview

A comprehensive course from UE C++ basics to a complete GAS multiplayer game, covering 37 chapters, 400+ lessons, with core code approximately 4 million lines distributed across 12+ UE projects and standalone programs.

### Chapter Structure
```
Basics (Ch1-3):     Environment Setup / Engine Architecture / Reflection System (UObject/CDO/GC)
Containers (Ch4-7): TArray / TMap / TSet / Basic Examples
Advanced API (Ch8-20): Timer / Delegate / String / Tag / Log / Subsystem
                       / Assert / Config / Smart Pointer / Multithreading / ControlFlows
                       / Plugin Development / Third-party Library Wrapping
Practical Examples (Ch21-36):
  Codec:         LibWebP encoding/display
  Desktop UI:    Slate standalone program
  Data:          JSON read/write
  Networking:    HTTP (3 chapters) / WebSocket (2 chapters) / WebSocketServer / TCP
  Multiplayer:   Network basics / DSM deployment / GAS case study
```

## Core Knowledge

### Container Selection Guide
| Container | Key Traits | Use Case |
|-----------|-----------|----------|
| TArray | Contiguous memory, random access O(1), append O(1), insert O(n) | Default choice, ordered collection |
| TMap | Hash table, key-value lookup O(1), unordered | Key-value mapping, dictionary queries |
| TSet | Hash set, unique elements, lookup O(1), unordered | Deduplication, membership tests |

Detailed references: `knowledge/ch4/` (TArray), `knowledge/ch5/` (TMap), `knowledge/ch6/` (TSet)

### Delegate System
| Declaration | Description |
|-------------|-------------|
| DECLARE_DELEGATE | Single-cast native delegate |
| DECLARE_MULTICAST_DELEGATE | Multi-cast native delegate |
| DECLARE_DYNAMIC_DELEGATE | Single-cast dynamic delegate (serializable) |
| DECLARE_DYNAMIC_MULTICAST_DELEGATE | Multi-cast dynamic delegate (Blueprint event dispatcher) |

Detailed references: `knowledge/ch9/` (7 files covering all delegate types)

### Async Execution Modes
| Pattern | Thread Model | Returns | Use Case |
|---------|-------------|---------|----------|
| FRunnable | OS independent thread | None (shared variables) | Long-running background tasks |
| Async() + TFuture | TaskGraph thread pool | Yes (TFuture.Get()) | Simple async computation |
| AsyncTask() | TaskGraph thread pool | No | Fire-and-forget tasks, thread jumping |
| FGraphEvent | TaskGraph thread pool, DAG | No | Multi-task dependency orchestration |
| ParallelFor | TaskGraph thread pool, parallel | No | Data-parallel computation |
| FControlFlow | Any thread (sequential execution) | No (Delegate callback) | Async step orchestration |
| ManageTask | GameThread Tick (custom) | No (three-phase callback) | Parallel task management |

Detailed references: `references/多线程详解.md`, `references/异步执行模式.md`, `references/ControlFlows详解.md`

### Configuration & Dependency Injection
```
Subsystem (Ch13):
  - UGameInstanceSubsystem   (GameInstance lifetime)
  - UWorldSubsystem          (World lifetime)
  - UEditorSubsystem         (Editor mode)
  - ULocalPlayerSubsystem    (Player lifetime)
  - UEngineSubsystem         (Engine global)

DeveloperSettings (Ch15):
  - UDeveloperSettings base class
  - UPROPERTY(Config) auto reads/writes INI
  - GetMutableDefault<T>() / GetDefault<T>()

CDO (Ch3):
  - GetClassDefaultObject()
  - Every UClass auto-creates one
  - Shares mechanism with Subsystem / DeveloperSettings
```

Detailed reference: `references/配置与依赖注入.md`

### Network Communication Evolution
```
HTTP (Ch25-28):
  - HttpRequest + FHttpModule (Get/Post/Put/Delete)
  - Sync/Async callback mode
  - File upload (camera image Base64)
  - Streaming (LLM SSE)

WebSocket (Ch29-30):
  - IWebSocket + FWebSocketsModule
  - Persistent connection, bidirectional communication
  - STT voice recognition (Subsystem resident + FRunnable audio capture)
  - TTS voice synthesis (AsyncAction single request)

WebSocketServer (Ch31):
  - IWebSocketServer (from WebSocketNetworking plugin)
  - Custom message protocol + connection container management
  - Heartbeat + state machine

TCP (Ch32):
  - FSocket + FTcpSocketBuilder
  - FRunnable long connection + SMTP protocol state machine
  - Async action (UBlueprintAsyncActionBase)
```

Detailed references: `references/HTTP通信详解.md`, `references/WebSocket通信详解.md`, `references/TCP通信详解.md`, `references/网络通信演进.md`

## Common Development Workflows

### Workflow 1: Add a New Container
```
1. Confirm requirements:
   - Need ordering? -> TArray
   - Need key-value mapping? -> TMap
   - Need unique element set? -> TSet
   - Need stack/queue ops? -> TQueue/TStack
2. Select container type (see references/容器选型指南.md)
3. Consider element type (UObject* vs TObjectPtr, value type vs direct element)
4. Consider copy semantics (UPROPERTY auto GC tracking)
5. Use Range-based for or iterator traversal
```

### Workflow 2: Send HTTP Request
```cpp
FHttpRequestRef Request = FHttpModule::Get().CreateRequest();
Request->SetURL(TEXT("https://api.example.com/data"));
Request->SetVerb(TEXT("GET"));
Request->SetHeader(TEXT("Content-Type"), TEXT("application/json"));

Request->OnProcessRequestComplete().BindLambda([](
    FHttpRequestPtr Req, FHttpResponsePtr Resp, bool bSuccess)
{
    if (bSuccess && Resp.IsValid())
    {
        FString ResponseStr = Resp->GetContentAsString();
    }
});

Request->ProcessRequest();
```

### Workflow 3: Create WebSocket Connection
```cpp
TSharedPtr<IWebSocket> WebSocket = FWebSocketsModule::Get().CreateWebSocket(URL, Protocol);
WebSocket->OnConnected().AddLambda([]() { UE_LOG(LogTemp, Log, TEXT("Connected")); });
WebSocket->OnConnectionError().AddLambda([](const FString& Error) { /* handle */ });
WebSocket->OnMessage().AddLambda([](const FString& Msg) { /* handle */ });
WebSocket->OnClosed().AddLambda([](int32 Code, const FString& Reason) { /* handle */ });
WebSocket->Connect();
WebSocket->Send(Message);
```

### Workflow 4: Create FRunnable Background Thread
```cpp
class FXGSimpleRunnable : public FRunnable
{
    virtual bool Init() override;
    virtual uint32 Run() override;
    virtual void Exit() override;
    virtual void Stop() override;
    FThreadSafeBool bRunning = true;
};
FRunnableThread::Create(ThreadObj, TEXT("ThreadName"));
ThreadObj->Stop();  // sets bRunning = false from external thread
```

### Workflow 5: Add New Subsystem
```cpp
UCLASS()
class UXGMySubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()
public:
    virtual void Initialize(FSubsystemCollectionBase& Collection) override;
    virtual void Deinitialize() override;
    UFUNCTION(BlueprintCallable)
    void MyFunction();
};
// Auto-created, no manual registration needed
```

### Workflow 6: Create Slate Standalone Program
```
1. INT32_MAIN_ENTRY entry point
2. FSimpleApplication initialization
3. SCompoundWidget-derived custom window
4. FSlateApplication::Get().AddWindow() display window
5. Message loop
```

### Workflow 7: Wrap Third-party C++ Library as Plugin
```
1. Create blank plugin (Editor or manual)
2. Configure third-party library paths and dependencies in Build.cs
3. Initialize library at plugin module startup
4. Wrap in UFUNCTION (use FString params, not std::string)
5. Configure plugin dependency: add to target project .uproject
```

## Key Class Index

### Reflection & Foundation
| Topic | Reference | Role |
|-------|-----------|------|
| UCLASS/USTRUCT/UENUM/UPROPERTY/UFUNCTION/UINTERFACE | Ch3 knowledge/ | 6 major reflection macro system |
| UObject | Engine built-in | GC base class, parent of all reflection classes |
| CDO (ClassDefaultObject) | Engine built-in | Default object shared per UClass instance |
| FAssetData | Engine built-in | Asset data for search/filter |

### Containers
See `knowledge/ch4/` (TArray, 14 files), `knowledge/ch5/` (TMap, 8 files), `knowledge/ch6/` (TSet, 5 files)

### Strings
| Topic | Reference | Role |
|-------|-----------|------|
| FString | knowledge/第十章-字符串.md | Mutable string, Printf/Format/Parse operations |
| FName | Engine built-in | Immutable atomic string, asset index/path lookup |
| FText | Engine built-in | Localized text, LOCTEXT/NSLOCTEXT |
| FTCHARToUTF8 / FUTF8ToTCHAR | Engine built-in | TCHAR <-> UTF8 encoding conversion |

### Subsystems
See `knowledge/第十三章-编程子系统.md`

### Multithreading
See `knowledge/第十七章-多线程.md`, `references/多线程详解.md`

### Smart Pointers
See `knowledge/第十六章-智能指针.md`, `references/智能指针详解.md`

### Logging & Assertion
See `knowledge/第十二章-日志记录.md`, `references/日志断言与调试.md`

### Network Communication
See `references/HTTP通信详解.md`, `references/WebSocket通信详解.md`, `references/TCP通信详解.md`, `references/网络通信演进.md`

### Network Replication
See `references/网络同步基础.md`

### GAS (Gameplay Ability System)
See `knowledge/第三十六章-虚幻高级网络游戏技能系统GAS案例.md`, `references/GAS体系详解.md`

### Enhanced Input
See `references/增强输入系统.md`

### Slate Standalone Programs
See `references/Slate独立程序详解.md`

### Third-party Library Integration
See `references/第三方库封装指南.md`

## Reference Document Index

All detailed references are in `references/` directory:

| Document | Description |
|----------|-------------|
| 反射系统总览.md | 6 major reflection macros selection + declaration positions + practical pitfalls |
| 容器选型指南.md | TArray/TMap/TSet comparison + performance traits + decision tree |
| TArray详解.md | TArray complete API + memory model + copy strategy |
| 委托体系详解.md | 4 delegate types + binding/broadcasting + usage patterns |
| 多线程详解.md | FRunnable/Async/FGraphEvent API + pitfalls |
| ControlFlows详解.md | FControlFlow + ManageTask async orchestration |
| 网络通信演进.md | HTTP -> WebSocket -> TCP progressive chain |
| HTTP通信详解.md | HTTP client/server + file upload + streaming |
| WebSocket通信详解.md | WebSocket client + STT/TTS + authentication |
| TCP通信详解.md | TCP connection + SMTP state machine + email sending |
| 配置与依赖注入.md | Subsystem/DeveloperSettings/CDO comparison |
| 异步执行模式.md | 6 async patterns + TaskGraph thread pool pitfalls |
| GAS体系详解.md | GAS core framework + AttributeSet + GEEC + GameplayAbility |
| Slate独立程序详解.md | Slate standalone program entry + window management + control system |
| 第三方库封装指南.md | Third-party library integration + plugin wrapping + cross-platform notes |
| 字符串处理详解.md | FString/FName/FText comparison + TCHAR encoding system + localization |
| 增强输入系统.md | Enhanced Input asset system + IMC registration + binding flow + weapon switch examples |
| 网络同步基础.md | Property sync + RPC + network roles + DSM three-tier deployment |
| 日志断言与调试.md | UE_LOG 7 verbosity levels + check/verify/ensure comparison + Dump debugging |
| 智能指针详解.md | TSharedPtr/TSharedRef/TUniquePtr/TWeakPtr + circular reference + UE vs STL |
| GameplayTag与定时器.md | FGameplayTag hierarchy matching + FTimerManager API + lifecycle management |

## Usage Examples

| Question | Reference Path |
|----------|---------------|
| "Which container should I use?" | references/容器选型指南.md |
| "How to make HTTP requests?" | references/HTTP通信详解.md |
| "Subsystem vs DeveloperSettings?" | references/配置与依赖注入.md |
| "How to run tasks on background thread?" | references/多线程详解.md |
| "How to wrap a C++ library as plugin?" | references/第三方库封装指南.md |
| "How to use WebSocket for real-time communication?" | references/WebSocket通信详解.md |
| "FControlFlow vs FRunnable?" | references/异步执行模式.md |
| "How to do damage calculation with GAS?" | references/GAS体系详解.md |
| "How to write a Slate standalone window?" | references/Slate独立程序详解.md |
| "UCLASS vs USTRUCT?" | references/反射系统总览.md |
| "How to use TCP for SMTP email?" | references/TCP通信详解.md |
| "FString vs FName vs FText?" | references/字符串处理详解.md |
| "How to use Enhanced Input in C++?" | references/增强输入系统.md |
| "How to use UE native network replication?" | references/网络同步基础.md |
| "check vs verify vs ensure?" | references/日志断言与调试.md |
| "How to solve smart pointer circular reference?" | references/智能指针详解.md |
| "How to use GameplayTag and Timer?" | references/GameplayTag与定时器.md |