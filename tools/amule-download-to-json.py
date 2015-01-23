#!/usr/bin/env python
import sys
import json
import re

class AmuleCmdDownloadFile(object):
	def __init__(self, filename, hash):
		self.filename = filename
		self.hash = hash

	def set_percentage(self, percentage):
		self.percentage = percentage

	def to_dict(self):
		return { 'filename': self.filename, 'hash': self.hash, 'percentage': self.percentage }

class AmuleCmdParser(object):
	'''
	Class to parse amulecmd 'show dl' and convert to objects.
	'''
	FIRST_LINE_RE = re.compile('^\s*>\s+(?P<hash>[^\s]+)\s(?P<filename>.+)$')
	SECOND_LINE_RE=re.compile('^\s*>\s+\[(?P<percentage>[^%]+)%\].+')
	def __init__(self):
		self.files = []
		self.status = 0 # waiting for a > with hash
		self.last_file = None

	def parse_line(self, line):
		line = line.strip()
		if self.status == 0:
			matches = AmuleCmdParser.FIRST_LINE_RE.match(line)
			if matches:
				if self.last_file:
					raise ValueError('Found match for file but file is not empty')
				self.last_file = AmuleCmdDownloadFile(matches.group('filename'), matches.group('hash'))
				self.status = 1
		else :
			matches = AmuleCmdParser.SECOND_LINE_RE.match(line)
			if matches:
				if not self.last_file:
					raise ValueError('Found match for percentage but file is empty')
				self.last_file.set_percentage(float(matches.group('percentage')))
				self.files.append(self.last_file)
				self.last_file = None
				self.status = 0
		
	def to_json(self):
		json_object = [ e.to_dict() for e in self.files ]
		return json.dumps(json_object)

if __name__ == "__main__":
	amule_parser = AmuleCmdParser()
	for line in sys.stdin:
		amule_parser.parse_line(line)
	print amule_parser.to_json()

