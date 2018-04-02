mythConfig=/etc/mythtv/config.xml
if [ -e "$mythConfig" ]; then
        mysqlUserOpt=$(sed $mythConfig -n -e '/<UserName/p')
        if [ -n "$mysqlUserOpt" ]; then
           mysqlUser=$(echo $mysqlUserOpt | sed 's: *</*UserName> *::g')
           mysqlArgs+=" -u $mysqlUser"
        fi
        mysqlPassOpt=$(sed $mythConfig -n -e '/<Password/p')
        if [ -n "$mysqlPassOpt" ]; then
           mysqlPass=$(echo $mysqlPassOpt | sed 's: *</*Password> *::g')
           if [ -n "$mysqlPass" ]; then
               mysqlArgs+=" -p$mysqlPass"
           fi
        fi
fi
echo $mysqlArgs
mysql $mysqlArgs mythconverg
