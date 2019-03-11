<?php
namespace Helper;

class System
{
    public static function getZendPHPVersion()
    {
        $bin     = self::getPHPCommand();
        $version = `$bin -r 'echo phpversion();'`;
        $version = trim($version);

        return $version;
    }

    public static function getPHPCommand()
    {
        $bin = '/usr/bin/php';

        return $bin;
    }
}