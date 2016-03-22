#!/bin/bash

function generateSshKeyIfMissing()
{
    mkdir -p /home/developer/.ssh
    chmod 700 -R /home/developer/.ssh
    chown developer.developer -R /home/developer/.ssh
    su developer -c '
        if [ ! -f ~/.ssh/id_rsa ]; then
          ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
        fi
    '
}

function composerCreate()
{
    disableXDebug
    setComposerPermission
    su developer -pc "composer create-project --no-dev"
    enableXDebug
}

function composerUp()
{
    disableXDebug
    setComposerPermission
    su developer -pc "composer up --no-dev"
    enableXDebug
}

function composerUpDev()
{
    disableXDebug
    setComposerPermission
    su developer -pc "composer up"
    enableXDebug
}

function setComposerPermission()
{
    mkdir -p /usr/local/lib/composer
    chown developer.developer -R /usr/local/lib/composer
    chmod g+rwxs -R /usr/local/lib/composer
    mkdir -p /tmp/composer/cache
    chown developer.developer -R /tmp/composer/cache
    chmod g+rwxs -R /tmp/composer/cache
}

function disableXDebug()
{
    local xDebugIniPath=$(getXDebugIniPath)
    local xDebugIniBackupPath=$(getXDebugIniBackupPath)
    mv $xDebugIniPath $xDebugIniBackupPath
}

function enableXDebug()
{
    local xDebugIniPath=$(getXDebugIniPath)
    local xDebugIniBackupPath=$(getXDebugIniBackupPath)
    mv $xDebugIniBackupPath $xDebugIniPath
}

function getXDebugIniPath()
{
    local xDebugIniPath='/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini'
    echo $xDebugIniPath
}

function getXDebugIniBackupPath()
{
    local xDebugIniBackupPath='/usr/local/etc/php/docker-php-ext-xdebug.ini'
    echo $xDebugIniBackupPath
}

function filteredPhpCodeSniffer()
{
    whitelist=/usr/local/etc/phpcs/lists/whitelist
    if [ ! -f ${whitelist} ]; then
        phpCodeSniff ${1}
    fi
    while read folder; do
        echo sniffing in ${folder}
        phpCodeSniff ${1} ${folder}
    done < ${whitelist}
}

function phpCodeSniff()
{
    standard=${1:-PSR2}
    folder=${2:-./}
    mkdir -p /usr/local/etc/phpcs/lists/
    touch /usr/local/etc/phpcs/lists/blacklist
    files=$(find ./${folder} -type f | grep -vf /usr/local/etc/phpcs/lists/blacklist | grep .php)
    disableXDebug
    phpcs --standard=${standard} ${files}
    enableXDebug
}

function updateTypo3Permission()
{
    echo '>> Setting file modes for TYPO3.'
    chown developer.developer -R /var/www/html/typo3temp /var/www/html/fileadmin
    chmod g+rwxs -R /var/www/html/typo3temp /var/www/html/fileadmin
}
