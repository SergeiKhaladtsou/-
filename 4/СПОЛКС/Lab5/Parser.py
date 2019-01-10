from argparse import ArgumentParser
from ICMP import main as run
from Config import PING_CMD
from Config import TRACE_CMD
from Config import SMURF_CMD


parser = ArgumentParser(description='ICMP utility')
subparsers = parser.add_subparsers(title="commands", dest="cmd")

# ping parser
ping = subparsers.add_parser(PING_CMD, help='Ping command')
ping.add_argument('-d', '--destination', action='append', required=True, type=str, help='Destination')
ping.add_argument('-b', '--broadcast', action='append', default='', type=str, help='Broadcast')
ping.add_argument('-n', type=int, default=4, help='Number of echo requests to send')

# traceroute parser
traceroute = subparsers.add_parser(TRACE_CMD, help='Traceroute command')
traceroute.add_argument('-d', '--destination', action='append', required=True, type=str, help='Destination')
traceroute.add_argument('-b', '--broadcast', action='append', type=str, default='', help='Broadcast')
traceroute.add_argument('-n', type=int, default=30, help='Number of echo requests to send')

# smurf parser
smurf = subparsers.add_parser(SMURF_CMD, help='Smurf command')
smurf.add_argument('-d', '--destination', action='append', required=True, type=str, help='Destination')
smurf.add_argument('-b', '--broadcast', action='append', required=True, type=str, help='Broadcast')
smurf.add_argument('-n', type=int, default=4, help='Number of echo requests to send')


while True:
    try:
        args = parser.parse_args(input('$: ').split())
    except SystemExit:
        continue
    run(args.destination, args.broadcast, args.cmd, args.n)
