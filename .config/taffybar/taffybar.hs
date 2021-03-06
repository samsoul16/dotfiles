{-# LANGUAGE OverloadedStrings #-}

import System.Taffybar

import System.Taffybar.FreedesktopNotifications
import System.Taffybar.MPRIS
import System.Taffybar.NetMonitor
import System.Taffybar.SimpleClock
import System.Taffybar.Systray
import System.Taffybar.TaffyPager
import System.Taffybar.CommandRunner
import System.Taffybar.Weather
import System.Process (readCreateProcess, shell)
import Data.Time.Clock (getCurrentTime)

import Data.Maybe (fromMaybe)

import System.Taffybar.Widgets.PollingBar
import System.Taffybar.Widgets.PollingGraph

import System.Information.Memory
import System.Information.Network
import System.Information.CPU

memCallback = do
  mi <- parseMeminfo
  return [memoryUsedRatio mi]

cpuCallback = do
  (userLoad, systemLoad, totalLoad) <- cpuLoad
  return [totalLoad, systemLoad]

netCallback = do
  minfo <- getNetInfo "eno1"
  return (maybe [0,0] (map fromInteger) minfo)

weatherConf :: WeatherConfig
weatherConf = (defaultWeatherConfig "CYVR") {
    weatherTemplate = "$tempC$ °C"
  }

noteConf = defaultNotificationConfig {notificationMaxTimeout = 5}

main = do
  time <- getCurrentTime
  netdev <- fmap init (readCreateProcess (shell "ip route get 8.8.8.8 | head -n1 | cut -d' ' -f5") "")
  let memCfg = defaultGraphConfig { graphDataColors = [(1, 0, 0, 1)]
                                  , graphLabel = Just "mem"
                                  }
      cpuCfg = defaultGraphConfig { graphDataColors = [ (0, 1, 0, 1)
                                                      , (1, 0, 1, 0.5)
                                                      ]
                                  , graphLabel = Just "cpu"
                                  }
      netCfg = defaultGraphConfig { graphDataColors = [ (0, 1, 0, 1)
                                                      , (1, 0, 1, 0.5)
                                                      ]
                                  , graphLabel = Just "net"
                                  }
  let clock = textClockNew Nothing "<span fgcolor='orange'>Week %W | %a %m/%e | %R</span>" 1
      pager = taffyPagerNew defaultPagerConfig
      note = notifyAreaNew noteConf
      wea = weatherNew weatherConf 10
      mpris = mprisNew defaultMPRISConfig
      mem = pollingGraphNew memCfg 1 memCallback
      cpu = pollingGraphNew cpuCfg 0.5 cpuCallback
      net = netMonitorNewWith 1.5 netdev 0 "▼ $inKB$KBps ▲ $outKB$KBps"
      cap = commandRunnerNew 5 "ds4_battery" [] "" "#ff6f6f"
      tray = systrayNew
  defaultTaffybar defaultTaffybarConfig { startWidgets = [ pager, note ]
                                        , endWidgets = reverse [ cap, mem, cpu, net, wea, clock, tray ]
                                        }
