# Custom Script v1.2 by DwiChan0905
# MikroTik Script for Telegram Bot
# Tested on MikroTik RB750 with RouterOS ver. 6.45.5
# just upload this file to your MikroTik's FTP. Then, import this file to apply the scripts.
# Telegram Bot Configurations is in tg_config.

/system scheduler
add interval=10s name=Telegram on-event="/system script run tg_getUpdates" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=sep/04/2019 start-time=18:28:04
add name="Reboot Report" on-event=\
    ":delay 30\r\
    \n/system script run reboot-report" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
/system script
add name=reboot-report policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local send [:parse [/system script get tg_sendMessage source]]\r\
    \n:put \$params\r\
    \n:put \$chatid\r\
    \n:put \$from\r\
    \n\r\
    \n:local reportBody \"\"\r\
    \n \r\
    \n:local deviceName [/system identity get name]\r\
    \n:local deviceDate [/system clock get date]\r\
    \n:local deviceTime [/system clock get time]\r\
    \n:local hwModel [/system routerboard get model]\r\
    \n:local rosVersion [/system package get system version]\r\
    \n:local currentFirmware [/system routerboard get current-firmware]\r\
    \n:local upgradeFirmware [/system routerboard get upgrade-firmware]\r\
    \n \r\
    \n \r\
    \n:set reportBody (\$reportBody . \"Router Reboot Report for \$deviceName%\
    0A\")\r\
    \n:set reportBody (\$reportBody . \"Report generated on \$deviceDate at \$\
    deviceTime%0A%0A\")\r\
    \n \r\
    \n:set reportBody (\$reportBody . \"Hardware Model: \$hwModel%0A\")\r\
    \n:set reportBody (\$reportBody . \"RouterOS Version: \$rosVersion%0A\")\r\
    \n:set reportBody (\$reportBody . \"Current Firmware: \$currentFirmware%0A\
    \")\r\
    \n:set reportBody (\$reportBody . \"Upgrade Firmware: \$upgradeFirmware\")\
    \r\
    \nif ( \$currentFirmware < \$upgradeFirmware) do={\r\
    \n:set reportBody (\$reportBody . \"NOTE: You should upgrade the RouterBOA\
    RD firmware!%0A\")\r\
    \n}\r\
    \n \r\
    \n:set reportBody (\$reportBody . \"%0A%0A=== Critical Log Events ===%0A\"\
    \_)\r\
    \n \r\
    \n:local x\r\
    \n:local ts\r\
    \n:local msg\r\
    \nforeach i in=([/log find where topics~\"critical\"]) do={\r\
    \n:set \$ts [/log get \$i time]\r\
    \n:set \$msg [/log get \$i message]\r\
    \n:set \$reportBody (\$reportBody  . \$ts . \" \" . \$msg . \"%0A\" )\r\
    \n}\r\
    \n \r\
    \n:set reportBody (\$reportBody . \"%0A=== end of report ===%0A\")\r\
    \n\$send chat=\$chatid text=\$reportBody mode=\"Markdown\""
add name=tg_getUpdates policy=read \
    source=":global TGLASTMSGID\r\
    \n:global TGLASTUPDID\r\
    \n\r\
    \n:local fconfig [:parse [/system script get tg_config source]]\r\
    \n:local http [:parse [/system script get func_fetch source]]\r\
    \n:local gkey [:parse [/system script get tg_getkey source]]\r\
    \n:local send [:parse [/system script get tg_sendMessage source]]\r\
    \n\r\
    \n:local cfg [\$fconfig]\r\
    \n:local trusted [:toarray (\$cfg->\"trusted\")]\r\
    \n:local botID (\$cfg->\"botAPI\")\r\
    \n:local storage (\$cfg->\"storage\")\r\
    \n:local timeout (\$cfg->\"timeout\")\r\
    \n\r\
    \n:put \"cfg=\$cfg\"\r\
    \n:put \"trusted=\$trusted\"\r\
    \n:put \"botID=\$botID\"\r\
    \n:put \"storage=\$storage\"\r\
    \n:put \"timeout=\$timeout\"\r\
    \n\r\
    \n:local file (\$storage.\"tg_get_updates.txt\")\r\
    \n:local logfile (\$storage.\"tg_fetch_log.txt\")\r\
    \n#get 1 message per time\r\
    \n:local url (\"https://api.telegram.org/bot\".\$botID.\"/getUpdates\?time\
    out=\$timeout&limit=1\")\r\
    \n:if ([:len \$TGLASTUPDID]>0) do={\r\
    \n  :set url \"\$url&offset=\$(\$TGLASTUPDID+1)\"\r\
    \n}\r\
    \n\r\
    \n:put \"Reading updates...\"\r\
    \n:local res [\$http dst-path=\$file url=\$url resfile=\$logfile]\r\
    \n:if (\$res!=\"success\") do={\r\
    \n  :put \"Error getting updates\"\r\
    \n  return \"Failed get updates\"\r\
    \n}\r\
    \n:put \"Finished to read updates.\"\r\
    \n\r\
    \n:local content [/file get [/file find name=\$file] contents]\r\
    \n\r\
    \n:local msgid [\$gkey key=\"message_id\" text=\$content]\r\
    \n:if (\$msgid=\"\") do={ \r\
    \n :put \"No new updates\"\r\
    \n :return 0 \r\
    \n}\r\
    \n:set TGLASTMSGID \$msgid\r\
    \n\r\
    \n:local updid [\$gkey key=\"update_id\" text=\$content]\r\
    \n:set TGLASTUPDID \$updid\r\
    \n\r\
    \n:local fromid [\$gkey block=\"from\" key=\"id\" text=\$content]\r\
    \n:local username [\$gkey block=\"from\" key=\"username\" text=\$content]\
    \r\
    \n:local firstname [\$gkey block=\"from\" key=\"first_name\" text=\$conten\
    t]\r\
    \n:local lastname [\$gkey block=\"from\" key=\"last_name\" text=\$content]\
    \r\
    \n:local chatid [\$gkey block=\"chat\" key=\"id\" text=\$content]\r\
    \n:local chattext [\$gkey block=\"chat\" key=\"text\" text=\$content]\r\
    \n\r\
    \n:put \"message id=\$msgid\"\r\
    \n:put \"update id=\$updid\"\r\
    \n:put \"from id=\$fromid\"\r\
    \n:put \"first name=\$firstname\"\r\
    \n:put \"last name=\$lastname\"\r\
    \n:put \"username=\$username\"\r\
    \n:local name \"\$firstname \$lastname\"\r\
    \n:if ([:len \$name]<2) do {\r\
    \n :set name \$username\r\
    \n}\r\
    \n\r\
    \n:put \"in chat=\$chatid\"\r\
    \n:put \"command=\$chattext\"\r\
    \n\r\
    \n:local allowed ( [:type [:find \$trusted \$fromid]]!=\"nil\" or [:type [\
    :find \$trusted \$chatid]]!=\"nil\")\r\
    \n:if (!\$allowed) do={\r\
    \n :put \"Unknown sender, keep silence\"\r\
    \n :return -1\r\
    \n}\r\
    \n\r\
    \n:local cmd \"\"\r\
    \n:local params \"\"\r\
    \n:local ltext [:len \$chattext]\r\
    \n\r\
    \n:local pos [:find \$chattext \" \"]\r\
    \n:if ([:type \$pos]=\"nil\") do={\r\
    \n :set cmd [:pick \$chattext 1 \$ltext]\r\
    \n} else={\r\
    \n :set cmd [:pick \$chattext 1 \$pos]\r\
    \n :set params [:pick \$chattext (\$pos+1) \$ltext]\r\
    \n}\r\
    \n\r\
    \n:local pos [:find \$cmd \"@\"]\r\
    \n:if ([:type \$pos]!=\"nil\") do={\r\
    \n :set cmd [:pick \$cmd 0 \$pos]\r\
    \n}\r\
    \n\r\
    \n\r\
    \n:put \"cmd=<\$cmd>\"\r\
    \n\r\
    \n:local alternativeCommand {\"hi\"=\"help\"; \"start\"=\"help\"; \"bantua\
    n\"=\"help\"; \"hello\"=\"help\"; \"halo\"=\"help\"; \"hai\"=\"help\"; \"h\
    s\"=\"hotspot\"; \"iface\"=\"interface\";\\\r\
    \n                          \"hotspotenable\"=\"enablehotspot\"; \"hotspot\
    disable\"=\"disablehotspot\"; \"monitor\"=\"monitoring\"; \"berhenti\"=\"s\
    top\"; \"watch\"=\"monitoring\";\\\r\
    \n                          \"restart\"=\"reboot\"}\r\
    \n:if ([:typeof (\$alternativeCommand -> \$cmd)] = \"str\") do={:set cmd (\
    \$alternativeCommand -> \$cmd); :put \"cmd=<\$cmd>\"}\r\
    \n\r\
    \n:put \"params=<\$params>\"\r\
    \n\r\
    \n:global TGLASTCMD \$cmd\r\
    \n\r\
    \n:put \"Try to invoke external script tg_cmd_\$cmd\"\r\
    \n:local script [:parse [/system script get \"tg_cmd_\$cmd\" source]]\r\
    \n\$script params=\$params chatid=\$chatid from=\$name"
add name=func_fetch policy=ftp,read,write,policy,test source="####\
    #####################################################\r\
    \n# Wrapper for /tools fetch\r\
    \n#  Input:\r\
    \n#    mode\r\
    \n#    upload=yes/no\r\
    \n#    user\r\
    \n#    password\r\
    \n#    address\r\
    \n#    host\r\
    \n#    httpdata\r\
    \n#    httpmethod\r\
    \n#    check-certificate\r\
    \n#    src-path\r\
    \n#    dst-path\r\
    \n#    ascii=yes/no\r\
    \n#    url\r\
    \n#    resfile\r\
    \n\r\
    \n:local res \"fetchresult.txt\"\r\
    \n:if ([:len \$resfile]>0) do={:set res \$resfile}\r\
    \n#:put \$res\r\
    \n\r\
    \n:local cmd \"/tool fetch\"\r\
    \n:if ([:len \$mode]>0) do={:set cmd \"\$cmd mode=\$mode\"}\r\
    \n:if ([:len \$upload]>0) do={:set cmd \"\$cmd upload=\$upload\"}\r\
    \n:if ([:len \$user]>0) do={:set cmd \"\$cmd user=\\\"\$user\\\"\"}\r\
    \n:if ([:len \$password]>0) do={:set cmd \"\$cmd password=\\\"\$password\\\
    \"\"}\r\
    \n:if ([:len \$address]>0) do={:set cmd \"\$cmd address=\\\"\$address\\\"\
    \"}\r\
    \n:if ([:len \$host]>0) do={:set cmd \"\$cmd host=\\\"\$host\\\"\"}\r\
    \n:if ([:len \$\"http-data\"]>0) do={:set cmd \"\$cmd http-data=\\\"\$\"ht\
    tp-data\"\\\"\"}\r\
    \n:if ([:len \$\"http-method\"]>0) do={:set cmd \"\$cmd http-method=\\\"\$\
    \"http-method\"\\\"\"}\r\
    \n:if ([:len \$\"check-certificate\"]>0) do={:set cmd \"\$cmd check-certif\
    icate=\\\"\$\"check-certificate\"\\\"\"}\r\
    \n:if ([:len \$\"src-path\"]>0) do={:set cmd \"\$cmd src-path=\\\"\$\"src-\
    path\"\\\"\"}\r\
    \n:if ([:len \$\"dst-path\"]>0) do={:set cmd \"\$cmd dst-path=\\\"\$\"dst-\
    path\"\\\"\"}\r\
    \n:if ([:len \$ascii]>0) do={:set cmd \"\$cmd ascii=\\\"\$ascii\\\"\"}\r\
    \n:if ([:len \$url]>0) do={:set cmd \"\$cmd url=\\\"\$url\\\"\"}\r\
    \n\r\
    \n:put \">> \$cmd\"\r\
    \n\r\
    \n:global FETCHRESULT\r\
    \n:set FETCHRESULT \"none\"\r\
    \n\r\
    \n:local script \"\\\r\
    \n :global FETCHRESULT;\\\r\
    \n :do {\\\r\
    \n   \$cmd;\\\r\
    \n   :set FETCHRESULT \\\"success\\\";\\\r\
    \n } on-error={\\\r\
    \n  :set FETCHRESULT \\\"failed\\\";\\\r\
    \n }\\\r\
    \n\"\r\
    \n:execute script=\$script file=\$res\r\
    \n:local cnt 0\r\
    \n#:put \"\$cnt -> \$FETCHRESULT\"\r\
    \n:while (\$cnt<100 and \$FETCHRESULT=\"none\") do={ \r\
    \n :delay 1s\r\
    \n :set \$cnt (\$cnt+1)\r\
    \n #:put \"\$cnt -> \$FETCHRESULT\"\r\
    \n}\r\
    \n:local content [/file get [find name=\$res] content]\r\
    \n#:put \$content\r\
    \nif (\$content~\"finished\") do={:return \"success\"}\r\
    \n:return \$FETCHRESULT"
add name=tg_getkey policy=read source=":local cur 0\r\
    \n:local lkey [:len \$key]\r\
    \n:local res \"\"\r\
    \n:local p\r\
    \n\r\
    \n:if ([:len \$block]>0) do={\r\
    \n :set p [:find \$text \$block \$cur]\r\
    \n :if ([:type \$p]=\"nil\") do={\r\
    \n  :return \$res\r\
    \n }\r\
    \n :set cur (\$p+[:len \$block]+2)\r\
    \n}\r\
    \n\r\
    \n:set p [:find \$text \$key \$cur]\r\
    \n:if ([:type \$p]!=\"nil\") do={\r\
    \n :set cur (\$p+lkey+2)\r\
    \n :set p [:find \$text \",\" \$cur]\r\
    \n :if ([:type \$p]!=\"nil\") do={\r\
    \n   if ([:pick \$text \$cur]=\"\\\"\") do={\r\
    \n    :set res [:pick \$text (\$cur+1) (\$p-1)]\r\
    \n   } else={\r\
    \n    :set res [:pick \$text \$cur \$p]\r\
    \n   }\r\
    \n } \r\
    \n}\r\
    \n:return \$res"
add name=tg_sendMessage policy=read source=":local fconfig [:parse\
    \_[/system script get tg_config source]]\r\
    \n\r\
    \n:local cfg [\$fconfig]\r\
    \n:local chatID (\$cfg->\"defaultChatID\")\r\
    \n:local botID (\$cfg->\"botAPI\")\r\
    \n:local storage (\$cfg->\"storage\")\r\
    \n\r\
    \n:if ([:len \$chat]>0) do={:set chatID \$chat}\r\
    \n\r\
    \n:local url \"https://api.telegram.org/bot\$botID/sendmessage\?chat_id=\$\
    chatID&text=\$text\"\r\
    \n:if ([:len \$mode]>0) do={:set url (\$url.\"&parse_mode=\$mode\")}\r\
    \n\r\
    \n:local file (\$tgStorage.\"tg_get_updates.txt\")\r\
    \n:local logfile (\$tgStorage.\"tg_fetch_log.txt\")\r\
    \n\r\
    \n/tool fetch url=\$url keep-result=no"
add name=tg_cmd_ping policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local send [:parse [/system script get tg_sendMessage source]]\r\
    \n:local param1 [:pick \$params 0 [:find \$params \" \"]]\r\
    \n:local param2 [:pick \$params ([:find \$params \" \"]+1) [:len \$params]\
    ]\r\
    \n\r\
    \n:put \$params\r\
    \n:put \$param1\r\
    \n:put \$param2\r\
    \n:put \$chatid\r\
    \n:put \$from\r\
    \n\r\
    \n:if (\$param1=\"to\") do={\r\
    \n#Ping Variables\r\
    \n:local avgRtt;\r\
    \n:local pin\r\
    \n:local pout\r\
    \n:local datetime \"\$[/system clock get date] \$[/system clock get time]\
    \"\r\
    \n#Ping it real good\r\
    \n/tool flood-ping \$param2 count=10 do={\r\
    \n  \r\
    \n:if (\$sent = 10) do={\r\
    \n    \r\
    \n:set avgRtt \$\"avg-rtt\"\r\
    \n    \r\
    \n:set pout \$sent\r\
    \n    \r\
    \n:set pin \$received\r\
    \n  }\r\
    \n\r\
    \n}\r\
    \n\r\
    \n:local ploss (100 - ((\$pin * 100) / \$pout))\r\
    \n\r\
    \n:local logmsg (\"Ping Average for \$param2 - \".[:tostr \$avgRtt].\"ms -\
    \_packet loss: \".[:tostr \$ploss].\"%\")\r\
    \n\r\
    \n:log info \$logmsg\r\
    \n\r\
    \n:local text \"Router ID:* \$[/system identity get name] * %0A\\\r\
    \nDate : _\$datetime_%0A\\\r\
    \nIP: _\$param2_%0A\\\r\
    \nResult:%0A_\$logmsg_\"\r\
    \n\$send chat=\$chatid text=\$text mode=\"Markdown\"\r\
    \n:return true\r\
    \n} else={\r\
    \n#Ping Variables\r\
    \n:local avgRtt;\r\
    \n:local pin\r\
    \n:local pout\r\
    \n:local datetime \"\$[/system clock get date] \$[/system clock get time]\
    \"\r\
    \n#Ping it real good\r\
    \n/tool flood-ping 8.8.8.8 count=10 do={\r\
    \n  \r\
    \n:if (\$sent = 10) do={\r\
    \n    \r\
    \n:set avgRtt \$\"avg-rtt\"\r\
    \n    \r\
    \n:set pout \$sent\r\
    \n    \r\
    \n:set pin \$received\r\
    \n  }\r\
    \n\r\
    \n}\r\
    \n\r\
    \n:local ploss (100 - ((\$pin * 100) / \$pout))\r\
    \n\r\
    \n:local logmsg (\"Ping Average for 8.8.8.8 - \".[:tostr \$avgRtt].\"ms - \
    packet loss: \".[:tostr \$ploss].\"%\")\r\
    \n\r\
    \n:log info \$logmsg\r\
    \n\r\
    \n:local text \"Router ID:* \$[/system identity get name] * %0A\\\r\
    \nDate : _\$datetime_%0A\\\r\
    \nIP: _8.8.8.8_%0A\\\r\
    \nResult:%0A_\$logmsg_\"\r\
    \n\$send chat=\$chatid text=\$text mode=\"Markdown\"\r\
    \n:return true\r\
    \n}"
add name=tg_config policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    #####################################\r\
    \n# Telegram bot API, VVS/BlackVS 2017\r\
    \n#                                Config file\r\
    \n######################################\r\
    \n:log info \"telegram configuration file has been loaded\";\r\
    \n\r\
    \n# to use config insert next lines:\r\
    \n#:local fconfig [:parse [/system script get tg_config source]]\r\
    \n#:local config [\$fconfig]\r\
    \n#:put \$config\r\
    \n\r\
    \n######################################\r\
    \n# Common parameters\r\
    \n######################################\r\
    \n\r\
    \n:local config {\r\
    \n\"Command\"=\"telegram\";\r\
    \n\t\"botAPI\"=\"xxxxxxxxxx:xxxxxxxxxxxxxxx-xxxxxxxxxxx\";\r\
    \n\t\"defaultChatID\"=\"xxxxxxxxx\";\r\
    \n\t\"trusted\"=\"xxxxxxxxx, -xxxxxxxxx\";\r\
    \n\t\"storage\"=\"\";\r\
    \n\t\"timeout\"=5;\r\
    \n\t\"refresh_active\"=15;\r\
    \n\t\"refresh_standby\"=300;\r\
    \n}\r\
    \nreturn \$config"
add name=tg_cmd_interface policy=read source=":local send [:parse [/system script get tg_sendMessage source]]\r\
    \n:local param1 [:pick \$params 0 [:find \$params \" \"]]\r\
    \n:local param2 [:pick \$params ([:find \$params \" \"]+1) [:len \$params]\
    ]\r\
    \n:local param3 [:pick [:pick \$params ([:find \$params \" \"]+1) [:len \$\
    params]] ([:find [:pick \$params ([:find \$params \" \"]+1) [:len \$params\
    ]] \" \"]+1) [:len [:pick \$params ([:find \$params \" \"]+1) [:len \$para\
    ms]]]]\r\
    \n:if ([:len [:find \$param2 \" \"]]>0) do={\r\
    \n\t:set param2 [:pick [:pick \$params ([:find \$params \" \"]+1) [:len \$\
    params]] 0 [:find [:pick \$params ([:find \$params \" \"]+1) [:len \$param\
    s]] \" \"]]\r\
    \n} else={\r\
    \n\t:set param3 \"\"\r\
    \n}\r\
    \n\r\
    \n:put \$params\r\
    \n:put \$param1\r\
    \n:put \$param2\r\
    \n:put \$param3\r\
    \n:put \$chatid\r\
    \n:put \$from\r\
    \n\r\
    \n:if (\$params=\"show\") do={\r\
    \n\t:local output \"Router ID:* \$[/system identity get name] * %0A%0A\"\r\
    \n\t:local eth01status\r\
    \n\t:local eth03status\r\
    \n\t:local eth04status\r\
    \n\t:local eth05status\r\
    \n\r\
    \n\t:if ([/interface ethernet get eth01-router running]=true) do={\r\
    \n\t\t:set eth01status (\"Internet is *CONNECTED*%0A\")\r\
    \n\t} else={\r\
    \n\t\t:set eth01status (\"Internet is *DISCONNECTED*%0A\")\r\
    \n\t}\r\
    \n\r\
    \n\t:if ([/interface ethernet get eth03-lantai-1 running]=true) do={\r\
    \n\t\t:set eth03status (\"Lantai 1 is *CONNECTED*%0A\")\r\
    \n\t} else={\r\
    \n\t\t:set eth03status (\"Lantai 1 is *DISCONNECTED*%0A\")\r\
    \n\t}\r\
    \n\r\
    \n\t:if ([/interface ethernet get eth04-lantai-2 running]=true) do={\r\
    \n\t\t:set eth04status (\"Lantai 2 is *CONNECTED*%0A\")\r\
    \n\t} else={\r\
    \n\t\t:set eth04status (\"Lantai 2 is *DISCONNECTED*%0A\")\r\
    \n\t}\r\
    \n\r\
    \n\t:if ([/interface ethernet get eth05-configurator running]=true) do={\r\
    \n\t\t:set eth05status (\"Config is *CONNECTED*%0A\")\r\
    \n\t} else={\r\
    \n\t\t:set eth05status (\"Config is *DISCONNECTED*%0A\")\r\
    \n\t}\r\
    \n\t:set output (\$output.\$eth01status.\$eth03status.\$eth04status.\$eth0\
    5status)\r\
    \n\t\$send chat=\$chatid text=(\"\$output\") mode=\"Markdown\"\r\
    \n}\r\
    \n:if ((\$param1=\"show\") and (\$param2=\"all\")) do={\r\
    \n\tlocal status \r\
    \n\tlocal name\r\
    \n\tforeach i in=[interface find] do={\r\
    \n\t\tset status (\$status,[/interface get value-name=running \$i])\r\
    \n\t\tset name (\$name,[/interface get value-name=name \$i])\r\
    \n\t}\r\
    \n\tput \$status\r\
    \n\tput \$name\r\
    \n\tlocal text\r\
    \n\tfor e from=0 to=([:len [interface find]] - 1) do={\r\
    \n\t\tlocal change {\"true\"=\"Connected\";\"false\"=\"Disconnected\"}\r\
    \n\t\tlocal newstatus (\$change->[:pick \$status \$e])\r\
    \n\t\tlocal before (\"%0AInterface \".[:pick \$name \$e].\" - Status: \".\
    \$newstatus)\r\
    \n\t\tput \$before\r\
    \n\t\tset text (\$text.\$before)\r\
    \n\t}\r\
    \n\tput \$text\r\
    \n\t\$send chat=\$chatid text=(\"\$text\") mode=\"Markdown\"\r\
    \n}\r\
    \n"
add name=func_lowercase policy=read \
    source="local alphabet {\"A\"=\"a\";\"B\"=\"b\";\"C\"=\"c\";\"D\"=\"d\";\"\
    E\"=\"e\";\"F\"=\"f\";\"G\"=\"g\";\"H\"=\"h\";\"I\"=\"i\";\"J\"=\"j\";\"K\
    \"=\"k\";\"L\"=\"l\";\"M\"=\"m\";\"N\"=\"n\";\"O\"=\"o\";\"P\"=\"p\";\"Q\"\
    =\"q\";\"R\"=\"r\";\"S\"=\"s\";\"T\"=\"t\";\"U\"=\"u\";\"V\"=\"v\";\"X\"=\
    \"x\";\"Z\"=\"z\";\"Y\"=\"y\";\"W\"=\"w\"};\r\
    \n:local result\r\
    \n:local character\r\
    \n:for strings from=0 to=([:len \$1] - 1) do={\r\
    \n\t:local single [:pick \$1 \$strings]\r\
    \n\t:set character (\$alphabet->\$single)\r\
    \n\t:if ([:typeof \$character] = \"str\") do={set single \$character}\r\
    \n\t:set result (\$result.\$single)\r\
    \n}\r\
    \n:return \$result"
