import requests
import re

headers = {'content-type': 'application/json'}
url = "http://192.168.2.50/wavemeter/wavemeter/wavemeter-status"
dataSend = "5|0|5|http://192.168.2.50/wavemeter/wavemeter/|CAE770F80E4A681B200769F57E4D8989|edu.umd.ion.wavemeter.service.WavemeterService|pollWavemeter|edu.umd.ion.wavemeter.service.WavemeterDataMask/1786418976|1|2|3|4|1|5|5|0|1918500334|"
headers = {'Content-Type':'text/x-gwt-rpc; charset=utf-8','X-GWT-Permutation':'E1D57440910859B69F5FD923FD39B973','X-GWT-Module-Base':'http://192.168.2.50/wavemeter/wavemeter/'}
r = requests.post(url, data=dataSend, headers = headers)

result = re.match(r"\/\/OK\[(.+)\]", r.text)
wavelengths = result.groups()[0].split(',')
print float(wavelengths[117])
print float(wavelengths[306])
#print result