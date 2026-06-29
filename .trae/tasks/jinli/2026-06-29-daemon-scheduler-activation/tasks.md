# Tasks: Daemon Scheduler Activation

## T1 DaemonScheduler Core

- [ ] T1.1: Create 
untime/daemon_scheduler.py with DaemonScheduler class (BackgroundScheduler, config loading, start/stop lifecycle)
- [ ] T1.2: Implement IdleTracker (Windows GetLastInputInfo + mark_activity fallback)
- [ ] T1.3: Implement scheduler job registration (6 timed jobs from the job table)
- [ ] T1.4: Implement /scheduler/status HTTP endpoint in api_server.py

## T2 Service Lifecycle Integration

- [ ] T2.1: Modify JinliDaemon.__init__ to accept optional DaemonScheduler
- [ ] T2.2: Modify JinliDaemon.start() to: (a) instantiate and start services, (b) start DaemonScheduler, (c) wire AfterTurnCommit sinks
- [ ] T2.3: Modify JinliDaemon.stop() to: (a) stop DaemonScheduler, (b) stop services, (c) unwire sinks
- [ ] T2.4: Modify _run_loop to remove the health-check loop (migrated to scheduler job health_check)

## T3 Sink Adapters

- [ ] T3.1: Create 
untime/sink_adapters.py with DreamerSinkAdapter, EvolutionSinkAdapter, ProactiveSinkAdapter
- [ ] T3.2: Each adapter implements _PendingSink protocol
- [ ] T3.3: Wire adapters into TurnOrchestrator's AfterTurnCommit during daemon start

## T4 Config and Docs

- [ ] T4.1: Create 
untime/scheduler.yaml with default config
- [ ] T4.2: Update 
untime-protocol.md with scheduler job table and /scheduler/status endpoint docs
- [ ] T4.3: Update 
untime-daemon-runbook.md with scheduler troubleshooting section

## T5 Tests

- [ ] T5.1: 	est_daemon_scheduler.py - scheduler start/stop, job registration, idle tracking, graceful degradation
- [ ] T5.2: 	est_sink_adapters.py - each adapter's enqueue behavior
- [ ] T5.3: Update 	est_daemon.py to verify scheduler lifecycle in daemon start/stop
- [ ] T5.4: Update 	est_after_turn_commit.py to include real sink adapters
- [ ] T5.5: Verify all 159+ existing tests still pass

## Dependency Order

T1 -> T2 -> T3 -> T5 (T4 can proceed in parallel with T2/T3)
