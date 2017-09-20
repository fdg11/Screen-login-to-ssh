SystemMountPoint="/";
LinesPrefix="  ";
b=$(tput bold);
n=$(tput sgr0);
i=$(tput blink);
cr=$(tput setaf 1);
cy=$(tput setaf 3)
cm=$(tput setaf 2);
 LL=$(lastlog | grep -v '*' | grep -vA 1 U | tr -s " ");
 Whoin=$(who -u);
 UserName=$(whoami);
  INFO=$(uname -r);
  LAN_IP=$(/sbin/ifconfig | grep -A 1 br0 | grep "inet" | cut -d"t" -f2 | cut -d" " -f2);
  HOST=$(hostname -s);
   
   SystemLoad=$(cat /proc/loadavg | cut -d" " -f1);
   ProcessesCount=$(cat /proc/loadavg | cut -d"/" -f2 | cut -d" " -f1);
    
    MountPointInfo=$(/bin/df -Th $SystemMountPoint 2>/dev/null | tail -n 1);
    MountPointFreeSpace=( \
      $(echo $MountPointInfo | awk '{ print $6 }') \
        $(echo $MountPointInfo | awk '{ print $3 }') \
        );
        UsersOnlineCount=$(users | wc -w);
         
         UsedRAMsize=$(free | awk 'FNR == 3 {printf("%.0f", $3/($3+$4)*100);}');
          
          SystemUptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/');
           clear;
           echo -e "${cr}${b}Last login:${n} ${cm}${LL}${n}";
           echo -e "${cr}${b}Who in system now:${n}\n${cm}${Whoin}${n}\n";
           echo -e "${LinesPrefix}${n}${cr}${i}Hello,${n} ${b}${UserName}${n}! ${cy}Welcome to ${b}${HOST}${n}\n";

            if [ ! -z "${LinesPrefix}" ] && [ ! -z "${SystemLoad}" ]; then
              echo -e "${LinesPrefix}${cm}${b}System load:${n}\t${SystemLoad}\t\t\t${LinesPrefix}${b}Processes:${n}\t\t${ProcessesCount}";
              fi;
               
               if [ ! -z "${MountPointFreeSpace[0]}" ] && [ ! -z "${MountPointFreeSpace[1]}" ]; then
                 echo -ne "${LinesPrefix}${cm}${b}Usage of $SystemMountPoint:${n}\t${MountPointFreeSpace[0]} of ${MountPointFreeSpace[1]}\t\t";
                 fi;
                 echo -e "${LinesPrefix}${b}Users logged in:${n}\t${UsersOnlineCount}";
                  
                  if [ ! -z "${UsedRAMsize}" ]; then
                    echo -ne "${LinesPrefix}${b}Memory usage:${n}\t${UsedRAMsize}%\t\t\t";
                    fi;
                    echo -e "${LinesPrefix}${b}System uptime:${n}\t${SystemUptime}";
                    echo -ne "${LinesPrefix}${b}LAN ip:${n}\t${LAN_IP}\t\t";
                    echo -e "${LinesPrefix}${b}Kernel release:${n}\t${INFO}\n\n\n";
                    