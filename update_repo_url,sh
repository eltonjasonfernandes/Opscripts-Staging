#!/bin/bash

while getopts ':v:' KEY $*
do
    case $KEY in
        v) version="| grep $OPTARG";;
        ?)  echo "FATAL: Unknown option $OPTARG"; echo "$USAGE" ; exit 0 ;;
    esac
done
shift $(($OPTIND - 1))

echo "##########################################################"
echo "Have you performed a backup via AWS Backup of all servers?" 
echo "            Required for all customer systems             "
echo "##########################################################"
echo "Press <ENTER> to continue or <CTRL>-C to abort"
read ignore
echo "##########################################################"
echo "    Have you taken a screenshot of the navigator page?    "
echo "##########################################################"
echo "        Are you running this in SCNREEN or TMUX?          "
echo "##########################################################"
echo "Press <ENTER> to continue or <CTRL>-C to abort"
read ignore

perl -le 'print $/ x 10'
date

apt_file=/etc/apt/sources.list.d/opsview.list
yum_file=/etc/yum.repos.d/opsview.repo
nightly=''

if grep -q nightly.opsview.com /opt/opsview/deploy/etc/user_vars.yml; then
  nightly='TRUE'
fi

if [[ -z "$nightly" ]]; then
  cmd="curl -sL https://downloads.opsview.com/opsview-commercial/506b910f-6d28-4107-875a-463f17293c97 | tail -1" 
  opsview_version="$(eval $cmd)"

  echo "# Latest Opsview Cloud version: $opsview_version"


  if [[ -f $apt_file ]]; then
    codename=$(lsb_release -s -c)
    if ! grep -q "$opsview_version" $apt_file; then

      echo "# Not found in $apt_file; adding"

      sed -i -e 's/^deb/#deb/' $apt_file

      echo "deb https://downloads.opsview.com/opsview-commercial/$opsview_version/apt $codename main" >> $apt_file
    fi
  elif [[ -f $yum_file ]]; then
    installed_version=$(rpm -qa --qf '%{VERSION}\n' opsview* | sort -n | tail -1)

    if ! grep -q "opsview-$opsview_version" $yum_file; then

      echo "# Not found in $yum_file; adding"

      cat >> $yum_file <<EOF
[opsview-$opsview_version]
baseurl = https://downloads.opsview.com/opsview-commercial/$opsview_version/yum/centos/\$releasever/\$basearch/
enabled = 1
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Opsview
name = Opsview

EOF
    fi
  else
    echo "Unknown OS"
    exit 1
  fi

  oc_file=/opt/opsview/deploy/etc/user_vars.yml

  if ! grep -q "$opsview_version" $oc_file; then

    echo "# Not found in $oc_file; adding"
    sed -i -e 's/^opsview_repository_version/#opsview_repository_version/' $oc_file

    echo "opsview_repository_version: $opsview_version" >> $oc_file
  fi
fi

version_lte() { 
  printf '%s\n%s' "$1" "$2" | sort -C -V 
}

version_lt() { 
  ! version_lte "$2" "$1" 
}

# Only on 6.5 systems and newer....
if ! version_lt "$opsview_version" "6.5.0.0"; then

  # check jwt config is removed from nginx for authorized_keys downloads
  if [[ -f /opt/opsview/webserver/etc/opsview-site-customisations.d/authorized_keys.conf ]]; then
    sed -i -e '/auth_jwt_enabled/d' /opt/opsview/webserver/etc/opsview-site-customisations.d/authorized_keys.conf
  fi
fi

# Only on 6.6.3 systems and newer....
if ! version_lt "$opsview_version" "6.6.3.0"; then

  # check jwt config is removed from nginx for authorized_keys downloads
  if [[ -f /opt/opsview/webserver/etc/opsview-site-customisations.d/cloud_api.conf ]]; then
    sed -i -e '/auth_tkt_/d' /opt/opsview/webserver/etc/opsview-site-customisations.d/cloud_api.conf
  fi
fi

#echo "# You now need to run opsview_deploy"
if [[ -f $apt_file ]]; then
  echo "apt update"
  echo "apt install -y opsview-python3 opsview-deploy"
  echo "apt autoremove -y"
else
  echo "yum clean all ; yum makecache fast"
  echo "yum install -y opsview-deploy"
fi
echo "#########"
echo "# IF THIS IS A CLOUD SYSTEM start the SSH support tunnel on all servers"
echo "# and make a note of the ports being used in case of an issue"
echo "/opt/opsview/supportscripts/bin/dosh -t opsview_all \"su - opsview -c 'curl -sLo- https://downloads.opsview.com/opsview-support/opsview_support_scripts | bash -s --'\""
echo "/opt/opsview/supportscripts/bin/dosh -t opsview_all \"su - opsview -c '/opt/opsview/supportscripts/bin/upgrade_tunnel start'\""
echo "/opt/opsview/supportscripts/bin/gen_ssh_config gen_upgrade_config"
echo "/opt/opsview/supportscripts/bin/acknowledgements export -u admin -p -f /var/tmp/acknowledgements-`date '+%Y%m%d%H%M%S'`"
echo "#########"
echo "cd /opt/opsview/deploy"
echo "rm -rf var/cache/facts/* var/fact_cache/*"
echo "bin/opsview-deploy lib/playbooks/check-deploy.yml"
echo "bin/opsview-deploy lib/playbooks/update-os-hosts.yml"
echo "bin/opsview-deploy lib/playbooks/setup-hosts.yml"
echo "bin/opsview-deploy lib/playbooks/setup-infrastructure.yml"
echo "bin/opsview-deploy lib/playbooks/setup-opsview.yml"

echo "###"
echo "### NOTE: next command will stop scheduler and other deamons ###"
echo "###       and make take some time to complete"
echo "bin/opsview-deploy lib/playbooks/datastore-reshard-data.yml"
echo "###"

if version_lt "$opsview_version" "6.3.0.0"; then
  #echo "Required for 6.3 and older"
  echo "su - opsview -c '/opt/opsview/coreutils/bin/import_all_opspacks -f'"
else
  # Do individual packages to avoid issues with local changes
  for pack in self-monitoring component-registry component-datastore component-messagequeue component-load-balancer; do
    echo "su - opsview -c '/opt/opsview/orchestrator/bin/orchestratorimportopspacks --force -o /opt/opsview/monitoringscripts/opspacks/opsview-${pack}.tar.gz'"
  done
fi
echo "bin/opsview-deploy lib/playbooks/sync_monitoringscripts.yml"
echo "bin/opsview-deploy lib/playbooks/setup-monitoring.yml"
echo "# --"
echo "# Also, if *cloud* or *managed* environment, run"
echo "su - opsview -c 'curl -sLo- https://downloads.opsview.com/opsview-support/opsview_cloud_opspack | bash -s --'"

echo "# Run any local postupgrade patching process"
echo "/opt/opsview/supportscripts/bin/dosh -t opsview_all \"(test -f /root/post_upgrade_patches && /root/post_upgrade_patches) || true\""

echo "#########"
echo "# IF THIS IS A CLOUD SYSTEM stop the SSH support tunnel on all servers"
echo "mv /root/.ssh/config.original /root/.ssh/config"
echo "/opt/opsview/supportscripts/bin/dosh -t opsview_all \"su - opsview -c '/opt/opsview/supportscripts/bin/upgrade_tunnel stop'\""

echo "#####################################"
echo "You should now run a reload in the UI"
echo "#####################################"

echo "#########"
echo "# IF REQUIRED restore Acknowledgements"
echo "/opt/opsview/supportscripts/bin/acknowledgements import -u admin -p -f /var/tmp/acknowledgements-`date '+%Y%m%d%H%M%S'`"
