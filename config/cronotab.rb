# cronotab.rb — Crono configuration file
Crono.perform(UpdateLocalDiskJob).every 10.minutes
Crono.perform(UpdateDownloadsJob).every 5.minutes
