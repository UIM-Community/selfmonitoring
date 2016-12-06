# Selfmonitoring
CA UIM Self monitoring probe. This probe has been created to do self monitoring of CA UIM Hubs and robots.

> Warning this probe only work on hub, the probe do local checkup with nimRequest only (dont use to do remote checkup). 

# Features 

- NisBridge Checkup (With HA Support) 
- Probe on hub checkup with HA Support (Callback & Down state).
- Hub robots intermediate and spooler checkup.
- UMP Monitoring

> Feel free to PR new monitoring 

# Installation and configuration guide 

> First of all, dont use nim_login and nim_password if you package the probe. Use these field when you run the script manually on the system. 

Dont forget you need perluim framework for this probe. Find the framework [HERE](https://github.com/fraxken/perluim)

### Setup section 

| Section | Key | Values | Description |
| --- | --- | --- | --- |
| setup | domain | string | CA UIM Domain |
| setup | audit | 1 - 0 |When audit is set to 1, the probe does not generate new alarms (cool to test in production the first time). |
| setup | callback_retry_count | number | Number of retries of primary callbacks (getrobots and probeslist). |
| setup | output_directory | string | the name of output directory. | 
| setup | output_cache_time | number | the cache time in second for output directory. |

### Configuration section 

| Section | Key | Values | Description |
| --- | --- | --- | --- |
| configuration | check_nisbridge | yes - no | Check Nis_bridge state (Support HA) |
| configuration | priority_on_ha | yes - no  | HA To rewrite 'alarm_on_probe_deactivated' to 1 on every probe (if ha_superiority is set to 'yes') |
| configuration/alarms | intermediate | 1 - 0 | Launch alarms when we detect intermediate robot. |
| configuration/alarms | spooler | 1 - 0 | Launch alarm when callback get_info fail on one robot spooler. |

### Probes_monitoring 

Setup your probes here. Callback is an optional key (no callback is the equivalent of probe down/up checkup). Set `alarm_on_probe_deactivated` to 0 if you want to not launch a alarm when the probe is offline. 

> Warning : alarm_on_probe_deactivated is rewrited by HA connected 0 if you have priority_on_ha set to yes.

Set `ha_superiority` to `no` if you dont want HA to rewrite the configuration.

##### Exemples 

```xml
<probes_monitoring>
    <discovery_server>
        callback = get_device_statistics
        alarm_on_probe_deactivated = 0
        ha_superiority = yes
    </discovery_server>
    <alarm_enrichment>
        callback = getStatistics
        alarm_on_probe_deactivated = 1
        ha_superiority = yes
    </alarm_enrichment>
    <prop_processor>
        alarm_on_probe_deactivated = 1
        ha_superiority = yes
    </prop_processor>
    <nas>
        callback = get_info
        alarm_on_probe_deactivated = 1
        ha_superiority = yes
        <check_keys>
            <pub_subscribers>
                <0>
                    name = NiS-Bridge
                    queue_len = <<100000
                </0>
            </pub_subcribers>
        </check_keys>
        check_alarm_name = checkconfig_nisbridge
    </nas>
</probes_monitoring>
```

## Alarms configuration 

Alarms message are configurable in the alarms_messages section. Variable are setted in the Script (so refer to this guide to use variables).

| Callback | Variables |
| --- | --- |
| callback_fail | $callback, $probe, $hubname |
| probe_offline | $probe, $hubname |
| spooler_fail | $robotname, $rc |
| intermediate_robot | $hubname, $robotname |
| nisbridge | $hubname, $robotname |

You can add easily your own variables in the code, just search for callback name. You will find a code like this : 

```perl
my $probe_offline = $alarm_manager->get('probe_offline');
my ($RC_ALARM,$AlarmID) = $probe_offline->call({ 
    probe => "$probe->{name}", 
    hubname => "$hub->{name}",
    customVar => "toto"
});
```

Juste add customVar like you want, and in the message use `$customVar` to print "toto". Feel free to pull-request new variables.

