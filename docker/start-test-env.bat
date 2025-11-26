@echo off
echo ═══════════════════════════════════════════════════════════════
echo   KryptoClaw Local Blockchain Test Environment
echo ═══════════════════════════════════════════════════════════════
echo.

echo Starting Docker containers...
docker-compose up -d

echo.
echo Waiting for nodes to initialize...
timeout /t 5 /nobreak > nul

echo.
echo ═══════════════════════════════════════════════════════════════
echo   ENDPOINTS READY:
echo ═══════════════════════════════════════════════════════════════
echo   Ethereum (Anvil):  http://localhost:8545
echo   Solana:            http://localhost:8899
echo   Bitcoin (Regtest): http://localhost:18443
echo   Unified Proxy:     http://localhost:8080
echo ═══════════════════════════════════════════════════════════════
echo.
echo Run 'docker-compose logs -f' to see live logs
echo Run 'docker-compose down' to stop
echo.
pause

