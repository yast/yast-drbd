
class DrbdParser

token TK_GLOBAL TK_RESOURCE TK_ON TK_NET TK_DISK_S TK_SYNCER TK_STARTUP TK_DISABLE_IP_VERIFICATION TK_PROTOCOL TK_ADDRESS TK_DISK TK_DEVICE TK_META_DISK TK_MINOR_COUNT TK_INTEGER TK_STRING TK_ON_IO_ERROR TK_SIZE TK_TIMEOUT TK_CONNECT_INT TK_PING_INT TK_MAX_BUFFERS TK_IPADDR TK_UNPLUG_WATERMARK TK_MAX_EPOCH_SIZE TK_SNDBUF_SIZE TK_RATE TK_AL_EXTENTS TK_WFC_TIMEOUT TK_DEGR_WFC_TIMEOUT TK_KO_COUNT TK_ON_DISCONNECT TK_DIALOG_REFRESH TK_USAGE_COUNT TK_COMMON TK_HANDLERS TK_FENCING TK_USE_BMBV TK_NO_DISK_BARRIER TK_NO_DISK_FLUSHES TK_NO_DISK_DRAIN TK_NO_MD_FLUSHES TK_MAX_BIO_BVECS TK_PINT_TIMEOUT TK_ALLOW_TWO_PRIMARIES TK_CRAM_HMAC_ALG TK_SHARED_SECRET TK_AFTER_SB_0PRI TK_AFTER_SB_1PRI TK_AFTER_SB_2PRI TK_DATA_INTEGRITY_ALG TK_RR_CONFLICT TK_NO_TCP_CORK TK_CPU_MASK TK_VERIFY_ALG TK_AFTER TK_FLEXIBLE_META_DISK TK_PRI_ON_INCON_DEGR TK_PRI_LOST_AFTER_SB TK_PRI_LOST TK_OUTDATE_PEER TK_LOCAL_IO_ERROR TK_SPLIT_BRAIN TK_BEFORE_RESYNC_TARGET TK_AFTER_RESYNC_TARGET TK_WAIT_AFTER_SB TK_BECOME_PRIMARY_ON TK_IPV6ADDR TK_IPV6 TK_FLOATING TK_STACK_ON_TOP_OF TK_MINOR

rule
	config: global_sec common_sec resources { $drbd['global'] = val[0]; $drbd['common'] = val[1]; $drbd['resources'] = val[2]; return $drbd; }

	global_sec: /* none */ { return {}; }
    	      | TK_GLOBAL '{' glob_stmts '}' { return val[2]; }
	glob_stmts: /* none */ { return {}; } 
        	  | glob_stmts glob_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }
	glob_stmt: TK_USAGE_COUNT TK_STRING { return ["#{val[0]}", val[1]]; }
             | TK_DISABLE_IP_VERIFICATION { return ["#{val[0]}", true]; }
		     | TK_MINOR_COUNT TK_STRING { return ["#{val[0]}", val[1]]; }
		     | TK_DIALOG_REFRESH TK_STRING { return ["#{val[0]}", val[1]];}

	common_sec: /* none */ { return {}; }		 
			 | TK_COMMON '{' common_stmts '}' { return val[2]; }
	common_stmts: /* none */ { return {}; }		 
			 | common_stmts common_stmt { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }

	common_stmt: TK_DISK_S disk_stmts '}' { return ["#{val[0]}", val[1]]; }
			| TK_NET '{' net_stmts '}' { return ["#{val[0]}", val[2]]; }
			| TK_SYNCER '{' sync_stmts '}' { return ["#{val[0]}", val[2]]; }
			| TK_STARTUP '{' startup_stmts '}' { return ["#{val[0]}", val[2]]; }
			| TK_HANDLERS '{' handlers_stmts '}' { return ["#{val[0]}", val[2]]; }
			| TK_PROTOCOL TK_STRING ';' { return ["#{val[0]}", val[1]]; }

	resources: /* none */ { return {}; }
	         | resources resource { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }

	resource: TK_RESOURCE resource_name '{' res_stmts '}' { return ["#{val[1]}", val[3]]; }

	resource_name: TK_STRING { return val[0]; }

	res_stmts: /* none */ { return {}; }
		| res_stmts res_stmt ';' { nk = val[1][0]; 
			                      if nk == "floating" then
								    if (!val[0]["floating"]) then val[0]["floating"] = {}; end
									val[0]["floating"][val[1][1]] = {}
								  else
			                        val[0][nk] = val[1][1]; 
								  end
								  return val[0]; }
		| res_stmts section {nk = val[1][0]; 
                                  if nk == "on" then 
				                      if (!val[0]["on"]) then val[0]["on"] = {}; end
                                      val[0]["on"][val[1][1]] = val[1][2];  
								  elsif nk == "floating" then
									  if (!val[0]["floating"]) then val[0]["floating"] = {}; end
									  val[0]["floating"][val[1][1]] = val[1][2];
								  elsif nk == "stacked-on-top-of" then
									  if (!val[0]["stacked-on-top-of"]) then val[0]["stacked-on-top-of"] = {}; end
									  val[0]["stacked-on-top-of"][val[1][1]] = val[1][2]
                                  else
                                      val[0][nk] = val[1][1]; 
                                  end
                                  return val[0]; }

	res_stmt: TK_PROTOCOL TK_STRING { return ["#{val[0]}", val[1]]; } 
		 | TK_DEVICE TK_STRING minor_stmt { return ["#{val[0]}", "#{val[1]} #{val[2]}"]; }
		 | TK_META_DISK meta_disk_and_index { return ["#{val[0]}", val[1]]; }
		 | TK_DISK TK_STRING { return ["#{val[0]}", val[1]]; }
		 | TK_FLOATING ip_and_port { return ["#{val[0]}", val[1]]; }

    minor_stmt: /* none */ { return ""; }
         | TK_MINOR TK_STRING { return "minor #{val[1]}"; } 

	section: TK_DISK_S disk_stmts '}' { return ["#{val[0]}", val[1]]; }
		   | TK_NET '{' net_stmts '}' { return ["#{val[0]}", val[2]]; }
		   | TK_SYNCER '{' sync_stmts '}' { return ["#{val[0]}", val[2]]; }
		   | TK_STARTUP '{' startup_stmts '}' { return ["#{val[0]}", val[2]]; }
		   | TK_HANDLERS '{' handlers_stmts '}' { return ["#{val[0]}", val[2]]; }
		   | TK_ON hostname '{' host_stmts '}' { return ["#{val[0]}", "#{val[1]}", val[3]]; }
		   | TK_FLOATING ip_and_port '{' floating_stmts '}' { return ["#{val[0]}", "#{val[1]}", val[3]]; }
		   | TK_STACK_ON_TOP_OF resource_name '{' stack_on_top_of_stmts '}' { return ["#{val[0]}", "#{val[1]}", val[3]]; }

	hostname: TK_STRING { return val[0]; }

	disk_stmts: /* none */ { return {}; }
              | disk_stmts disk_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }
	
	disk_stmt: TK_ON_IO_ERROR TK_STRING { return ["#{val[0]}", val[1]]; }
		     | TK_SIZE TK_STRING { return ["#{val[0]}", val[1]]; }
		     | TK_FENCING TK_STRING { return ["#{val[0]}", val[1]]; }
		     | TK_USE_BMBV TK_STRING { return ["#{val[0]}", val[1]]; }
		     | TK_NO_DISK_BARRIER TK_STRING { return ["#{val[0]}", val[1]]; }
		     | TK_NO_DISK_FLUSHES TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_NO_DISK_DRAIN  TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_NO_MD_FLUSHES  TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_MAX_BIO_BVECS TK_STRING { return ["#{val[0]}", val[1]]; }

	net_stmts: /* none */ { return {}; }
             | net_stmts net_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; } 

	net_stmt: TK_TIMEOUT TK_STRING { return ["#{val[0]}", val[1]]; }
		    | TK_CONNECT_INT TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_PING_INT TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_PINT_TIMEOUT TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_MAX_BUFFERS TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_UNPLUG_WATERMARK TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_MAX_EPOCH_SIZE TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_SNDBUF_SIZE TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_KO_COUNT TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_ALLOW_TWO_PRIMARIES { return ["#{val[0]}", true]; }
			| TK_CRAM_HMAC_ALG TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_SHARED_SECRET TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_AFTER_SB_0PRI TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_AFTER_SB_1PRI TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_AFTER_SB_2PRI TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_DATA_INTEGRITY_ALG TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_RR_CONFLICT TK_STRING { return ["#{val[0]}", val[1]]; }
			| TK_NO_TCP_CORK { return ["#{val[0]}", true]; }

	sync_stmts: /* none */  { return {}; }
	          | sync_stmts sync_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }

	sync_stmt: TK_RATE TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_CPU_MASK TK_STRING { return ["#{val[0]}", vavl[1]]; }
			 | TK_VERIFY_ALG TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_AFTER TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_AL_EXTENTS TK_STRING { return ["#{val[0]}", val[1]]; }

	floating_stmts: /* none */ { return {}; }
	         | floating_stmts floating_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }

	floating_stmt: TK_DISK TK_STRING { return ["#{val[0]}", val[1]]; }
             | TK_DEVICE TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_META_DISK meta_disk_and_index { return ["#{val[0]}", val[1]]; }
			 | TK_FLEXIBLE_META_DISK flexible_meta_disk { return ["#{val[0]}", val[1]]; }

	stack_on_top_of_stmts: /* none */ { return {}; }
	         | stack_on_top_of_stmts stack_on_top_of_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }

	stack_on_top_of_stmt: TK_DEVICE TK_STRING { return ["#{val[0]}", val[1]]; }
       	     | TK_ADDRESS ip_and_port { return ["#{val[0]}", val[1]]; }

	host_stmts: /* none */ { return {}; }
             | host_stmts host_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }

	host_stmt: TK_DISK TK_STRING { return ["#{val[0]}", val[1]]; }
             | TK_DEVICE TK_STRING minor_stmt { return ["#{val[0]}", "#{val[1]} #{val[2]}"]; }
			 | TK_ADDRESS ip_and_port { return ["#{val[0]}", val[1]]; }
			 | TK_META_DISK meta_disk_and_index { return ["#{val[0]}", val[1]]; }
			 | TK_FLEXIBLE_META_DISK flexible_meta_disk { return ["#{val[0]}", val[1]]; }

	handlers_stmts: /* none */ { return {}; }
			 | handlers_stmts handlers_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }

	handlers_stmt: TK_PRI_ON_INCON_DEGR TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_PRI_LOST_AFTER_SB TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_PRI_LOST TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_OUTDATE_PEER TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_LOCAL_IO_ERROR TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_SPLIT_BRAIN TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_BEFORE_RESYNC_TARGET TK_STRING { return ["#{val[0]}", val[1]]; }
			 | TK_AFTER_RESYNC_TARGET TK_STRING { return ["#{val[0]}", val[1]]; }

	ip_and_port: TK_STRING ':' TK_STRING { return "#{val[0]}:#{val[2]}"; }
			 | TK_IPV6 TK_IPV6ADDR ":" TK_STRING { return "#{val[0]} #{val[1]}:#{val[3]}"; }
			 | TK_STRING TK_STRING ':' TK_STRING { return "#{val[0]} #{val[1]}:#{val[3]}"; }
			 | TK_STRING { return "#{val[0]}"; }

	meta_disk_and_index: TK_STRING TK_STRING { return "#{val[0]} #{val[1]}"; }
 		       | TK_STRING { return val[0]; }
			 
	flexible_meta_disk: TK_STRING { return val[0]; }

	startup_stmts: /* */ { return {}; }
	             | startup_stmts startup_stmt ';' { nk = val[1][0]; val[0][nk] = val[1][1]; return val[0]; }

	startup_stmt: TK_WFC_TIMEOUT TK_STRING { return ["#{val[0]}", val[1]]; }
				| TK_WAIT_AFTER_SB { return ["#{val[0]}", true]; }
				| TK_BECOME_PRIMARY_ON TK_STRING { return ["#{val[0]}", val[1]]; }
		        | TK_DEGR_WFC_TIMEOUT TK_STRING { return ["#{val[0]}", val[1]]; }

end			 

---- header
$drbd = Hash.new()

---- inner	
	def parse(str)
		@yydebug = false
		@q = []
		until str.empty? || !str
			case str
			when /\A\s+/
			when /\Adisable-ip-verification/
				@q.push [:TK_DISABLE_IP_VERIFICATION, 'disable-ip-verification']
			when /\Ausage-count/
				@q.push [:TK_USAGE_COUNT, 'usage-count']
			when /\Adialog-refresh/
				@q.push [:TK_DIALOG_REFRESH, 'dialog-refresh']	
			when /\Aon-io-error/
				@q.push [:TK_ON_IO_ERROR, 'on-io-error']
			when /\Aglobal/
				@q.push [:TK_GLOBAL, 'global']
			when /\Aminor-count/
				@q.push [:TK_MINOR_COUNT, 'minor-count']
			when /\Aresource[ \t\n]/
				@q.push [:TK_RESOURCE, 'resource']
			when /\Acommon/
				@q.push [:TK_COMMON, 'common']	
			when /\Aprotocol/
				@q.push [:TK_PROTOCOL, 'protocol']
			when /\Adisk\s*\{/
				@q.push [:TK_DISK_S, 'disk_s']
			when /\Adisk/
				@q.push [:TK_DISK, 'disk']
			when /\Anet/
				@q.push [:TK_NET, 'net']
			when /\Aminor/
				@q.push [:TK_MINOR, 'minor']
			when /\Asyncer/
				@q.push [:TK_SYNCER, 'syncer']
			when /\Astartup/
				@q.push [:TK_STARTUP, 'startup']
			when /\Ahandlers/
				@q.push [:TK_HANDLERS, 'handlers']	
			when /\Afencing/
				@q.push [:TK_FENCING, 'fencing']	
			when /\Ause-bmbv/
				@q.push [:TK_USE_BMBV, 'use-bmbv']
			when /\Ano-disk-barrier/
				@q.push [:TK_NO_DISK_BARRIER, 'no-disk-barrier']
			when /\Ano-disk-flushes/
				@q.push [:TK_NO_DISK_FLUSHES, 'no-disk-flushes']
			when /\Ano-disk-drain/
				@q.push [:TK_NO_DISK_DRAIN, 'no-disk-drain']
			when /\Ano-md-flushes/
				@q.push [:TK_NO_MD_FLUSHES, 'no-md-flushes']
			when /\Amax-bio-bvecs/
				@q.push [:TK_MAX_BIO_BVECS, 'max-bio-bvecs']
			when /\Aping-timeout/
				@q.push [:TK_PING_TIMEOUT, 'ping-timeout']
			when /\Aallow-two-primaries/
				@q.push [:TK_ALLOW_TWO_PRIMARIES, 'allow-two-primaries']
			when /\Acram-hmac-alg/
				@q.push [:TK_CRAM_HMAC_ALG, 'cram-hmac-alg']
			when /\Ashared-secret/
				@q.push [:TK_SHARED_SECRET, 'shared-secret']
			when /\Aafter-sb-0pri/
				@q.push [:TK_AFTER_SB_0PRI, 'after-sb-0pri']
			when /\Aafter-sb-1pri/
				@q.push [:TK_AFTER_SB_0PRI, 'after-sb-1pri']
			when /\Aafter-sb-2pri/
				@q.push [:TK_AFTER_SB_0PRI, 'after-sb-2pri']
			when /\Adata-integrity-alg/
				@q.push [:TK_DATA_INTEGRITY_ALG, 'data-integrity-alg']	
			when /\Arr-conflict/
				@q.push [:TK_RR_CONFLICT, 'rr-conflict']
			when /\Apri-on-incon-degr/
				@q.push [:TK_PRI_ON_INCON_DEGR, 'pri-on-incon-degr']
			when /\Apri-lost-after-sb/
				@q.push [:TK_PRI_LOST_AFTER_SB, 'pri-lost-after-sb']
			when /\Apri-lost/
				@q.push [:TK_PRI_LOST, 'pri-lost']	
			when /\Aoutdate-peer/
				@q.push [:TK_OUTDATE_PEER, 'outdate-peer']
			when /\Alocal-io-error/
				@q.push [:TK_LOCAL_IO_ERROR, 'local-io-error']
			when /\Asplit-brain/
				@q.push [:TK_SPLIT_BRAIN, 'split-brain']
			when /\Abefore-resync-target/
				@q.push [:TK_BEFORE_RESYNC_TARGET, 'before-rsync-target']
			when /\Aafter-resync-target/
				@q.push [:TK_AFTER_RESYNC_TARGET, 'after-resync-target']
			when /\Await-after-sb/
				@q.push [:TK_WAIT_AFTER_SB, 'wait-after-sb']
			when /\Abecome-primary-on/
				@q.push [:TK_BECOME_PRIMARY_ON, 'become-primary-on']	
			when /\Ano-tcp-cork/
				@q.push [:TK_NO_TCP_CORK, 'no-tcp-cork']
			when /\Acpu-mask/
				@q.push [:TK_CPU_MASK, 'cpu-mask']
			when /\Averify-alg/
				@q.push [:TK_VERIFY_ALG, 'verify-alg']	
			when /\Afloating/
			    @q.push [:TK_FLOATING, 'floating']
			when /\Astacked-on-top-of/
				@q.push [:TK_STACK_ON_TOP_OF, 'stacked-on-top-of']
			when /\Asize/
				@q.push [:TK_SIZE, 'size']
			when /\Atimeout/
				@q.push [:TK_TIMEOUT, 'timeout']
			when /\Aconnect-int/
				@q.push [:TK_CONNECT_INT, 'connect-int']
			when /\Aafter-sb-0pri/
				@q.push [:TK_AFTER_SB_0PRI, 'after-sb-0pri']
			when /\Aafter-sb-1pri/
				@q.push [:TK_AFTER_SB_0PRI, 'after-sb-1pri']
			when /\Aafter-sb-2pri/
				@q.push [:TK_AFTER_SB_0PRI, 'after-sb-2pri']
			when /\Arr-conflict/
				@q.push [:TK_RR_CONFLICT, 'rr-conflict']	
			when /\Aping-int/
				@q.push [:TK_PING_INT, 'ping-int']
			when /\Amax-buffers/
				@q.push [:TK_MAX_BUFFERS, 'max-buffers']
			when /\Aunplug-watermark/
				@q.push [:TK_UNPLUG_WATERMARK, 'unplug-watermark']
			when /\Amax-epoch-size/
				@q.push [:TK_MAX_EPOCH_SIZE, 'max-epoch-size']
			when /\Asndbuf-size/
				@q.push [:TK_SNDBUF_SIZE, 'sndbuf-size']
			when /\Ako-count/
				@q.push [:TK_KO_COUNT, 'ko-count']
			when /\Arate/
				@q.push [:TK_RATE, 'rate']
			when /\Aal-extents/
				@q.push [:TK_AL_EXTENTS, 'al-extents']
			when /\Aafter/
				@q.push [:TK_AFTER, 'after']	
			when /\Adevice/
				@q.push [:TK_DEVICE, 'device']
			when /\Aaddress/
				@q.push [:TK_ADDRESS, 'address']
			when /\Ameta-disk/
				@q.push [:TK_META_DISK, 'meta-disk']
			when /\Aflexible-meta-disk/
				@q.push [:TK_FLEXIBLE_META_DISK, 'flexible-meta-disk']	
			when /\Adegr-wfc-timeout/
				@q.push [:TK_DEGR_WFC_TIMEOUT, 'degr-wfc-timeout']
			when /\Awfc-timeout/
				@q.push [:TK_WFC_TIMEOUT, 'wfc-timeout']
			when /\Aipv6/
				@q.push [:TK_IPV6, 'ipv6']	
			when /\Aon\s*/
				@q.push [:TK_ON, 'on']
			when /\A"[^"]*"/
				@q.push [:TK_STRING, $&]
			when /\A\[[\w\.\/:]+:[\w\.\/:]+\]/
				@q.push [:TK_IPV6ADDR, $&]	
			when /\A[\w\.\/\[\]-]+/
				@q.push [:TK_STRING, $&]
			when /\A.|\n/o
				s = $&
				@q.push [s, s]
			end
			str = $'
		end
		@q.push [false, '$end']	
		do_parse
	end

	def next_token
		@q.shift
	end	
			
---- footer
dp = DrbdParser.new

$drbdcfg = "/etc/drbd.conf"
$configstr = ""
in_skip = false

if !File.exist?($drbdcfg+".YaST2prepare")
	file = File.open($drbdcfg+".YaST2prepare", "w")
        file.close
end


File.open($drbdcfg+".YaST2prepare", "r") do |file|
   file.each_line do |line| 
      line = line.gsub(/#.*$/, '').chomp
      if (line =~ /^skip\s+/) then in_skip = true end
      if (line =~ /^\}/ && in_skip == true) then 
      	 in_skip = false 
         line = ""
      end
      if (! in_skip ) then
         $configstr += line.gsub(/#.*$/, '').chomp
      end
   end
end

dp.parse($configstr)



$debug = 0
def errlog (str)
    if $debug == 1 then
	$stderr.puts str
    end
end	

def convertYcp (str)
    return str.gsub(/"/, '\"')
end

def doList (path)
  if path.length == 0 then
    puts "[ \"global\", \"resources\", \"common\" ]"
    return
  end

  res = $drbd
  begin
    path.each do |it|
	  errlog it.to_s
	  errlog "xxx"+res.to_s
	  if res.has_key?(it.chomp) then
		res = res[it.chomp]
      else
	    errlog "quit as not key. " + it
        puts "nil"
        return
      end
    end

	errlog "xxx"+res.to_s
	errlog "xxx"+$drbd.to_s

	if res == nil then
		puts "nil"
		return
	end

    if res.length == 0 then
       str = "[]"
    else
       str = "[ "
       res.keys.each do |key|
          str = str + "\"" + convertYcp(key.to_s) + "\", "
       end
       str = str.chop.chop + " ]"
    end
	puts str
    return

  rescue NoMethodError
    errlog "quit as exceptions happends."
    puts "nil"
    return
  end
end

def doRead(path)
  if path.length == 0 then
    puts "nil"
    return
  end

  res = $drbd
  begin
    path.each do |it|
      if res.has_key?(it.chomp) then
        res = res[it.chomp]
      else
        puts "nil"
        return
      end
    end

    puts '"'+convertYcp(res.to_s)+'"'
    return 
  rescue NoMethodError
    puts "nil"
    return
  end

end

def stripQuote(path)
  path.each_index do |it|
    if ! path[it] == "" and path[it][0] == '"' then
	  path[it]=path[it][1..-2]
	end
  end
  return path
end

def doWrite(path, args)
  errlog "write path is "+path.to_s
  errlog "write args is "+args

  if path.length == 0 then
    commitChange()
    puts "nil"
    return
  end

  path.each_index do |it|
    errlog "found "+path[it]
    if path[it] != "" and path[it][0] == '"' then
	  errlog path[it]+" is changed to "+path[it].chomp()[1..-2]
      path[it]=path[it].chomp()[1..-2]
    end
	if path[it] != "" and path[it][0..1] == "\\\"" then
		errlog path[it]+" is changed to "+path[it].chomp()[1..-3]+"\""
		path[it]=path[it].chomp()[1..-3]+"\""
	end
  end

  if args[0..1] == "\\\"" then
    errlog "args is changed to " + args[1..-3] + "\""
	args = args.chomp()[1..-3]+"\""
  end

  errlog path.to_s

  if path.length < 2 then
    puts "nil"
    return
  end

  if path[-2].chomp == "on" then
    errlog "prepare to change the node name"
    res = $drbd
    res_b = res
    begin
      path.each do |it|
        if res.has_key?(it.chomp) then
          res_b = res
          res = res[it.chomp]
        else
		  puts "nil"
		  return
        end
      end

      errlog "found the node name, change it"
	  if args != "nil" then
        res_b.delete(args)
        res_b[args] = res_b[path[-1].chomp]
        res_b.delete(path[-1].chomp)
	  else
	    res_b.delete(path[-1].chomp)
	  end
      writeFile
      puts "nil"
      return
    rescue
      puts "nil"
      return
    end

  elsif path[-2].chomp == "resources" then
    errlog "prepare to change the resource name"
    if $drbd["resources"].has_key?(path[-1].chomp) then
	  if args != "nil" then
        $drbd["resources"].delete(args)
        $drbd["resources"][args] = $drbd["resources"][path[-1].chomp]
        $drbd["resources"].delete(path[-1].chomp)
	  else
	    $drbd["resources"].delete(path[-1].chomp)
      end	  
      writeFile
      puts "nil"
      return
    end

  else
    errlog "prepare to change the attribute"
    res = $drbd
    res_b = res
    begin
      path.each do |it|
        if res.has_key?(it.chomp) then
          res_b = res
          res = res[it.chomp]
        else
		  res[it.chomp] = Hash.new()
		  res_b = res
		  res = res[it.chomp]
        end
      end

      errlog "found the attribute name, change it"
	  if args != "nil" then
        res_b[path[-1].chomp] = args
	  else
        res_b.delete(path[-1].chomp)
      end	
      writeFile
      puts "nil"
      return
    rescue
      puts "nil"
      return
    end
  end
  puts "nil"
end

def writeFile()
  errlog $drbd.to_s	
  errlog "start to writeFile"
  File.open($drbdcfg+".YaST2new", "w") do |file|
    file.puts "# YaST2 created seperated configuration file"
    file.puts "include \"/etc/drbd.d/global_common.conf\";"
	File.open("/etc/drbd.d/global_common.conf.YaST2new", "w") do |gccfile|

    if $drbd.has_key?("global") then
      gccfile.puts "global {"
      $drbd["global"].each_key do |key|
	    if key == "disable-ip-verification" then
		  if $drbd["global"][key] == "" or $drbd["global"][key] == "true" then
		    gccfile.puts "   "+key+";"
		  end
		else
          gccfile.puts "   "+key+"\t"+$drbd["global"][key]+";"
		end
      end
      gccfile.puts "}"
    end # <-- has global

	if $drbd.has_key?("common") then
		gccfile.puts "common {"

        if $drbd["common"].has_key?("disk_s") then
          gccfile.puts "   disk {"
          $drbd["common"]["disk_s"].each_key do |key|
            gccfile.puts "      "+key+"\t"+$drbd["common"]["disk_s"][key]+";"
          end
          gccfile.puts "   }"
        end

        if $drbd["common"].has_key?("syncer") then
          gccfile.puts "   syncer {"
          $drbd["common"]["syncer"].each_key do |key|
            gccfile.puts "      "+key+"\t"+$drbd["common"]["syncer"][key]+";"
          end
          gccfile.puts "   }"
        end

        if $drbd["common"].has_key?("net") then
          gccfile.puts "   net {"
          $drbd["common"]["net"].each_key do |key|
            gccfile.puts "      "+key+"\t"+$drbd["common"]["net"][key]+";"
          end
          gccfile.puts "   }"
        end

        if $drbd["common"].has_key?("startup") then
          gccfile.puts "   startup {"
          $drbd["common"]["startup"].each_key do |key|
            gccfile.puts "      "+key+"\t"+$drbd["common"]["startup"][key]+";"
          end
          gccfile.puts "   }"
        end

        if $drbd["common"].has_key?("handlers") then
          gccfile.puts "   handlers {"
          $drbd["common"]["handlers"].each_key do |key|
            gccfile.puts "      "+key+"\t"+$drbd["common"]["handlers"][key]+";"
          end
          gccfile.puts "   }"
        end

		gccfile.puts "}"
	end # <-- has common

	end # <-- end of File.open(gccfile)

    if $drbd.has_key?("resources") then
      $drbd["resources"].each_key do |res_name|

	    file.puts "include \"/etc/drbd.d/"+res_name+".res\";" # <-- put the config of resource into a split file.

		File.open("/etc/drbd.d/"+res_name+".res.YaST2new", "w") do |resfile|

        resfile.puts "resource "+res_name+" {"

        if $drbd["resources"][res_name].has_key?("protocol") then
          resfile.puts "   protocol\t"+$drbd["resources"][res_name]["protocol"]+";"
        end
		if $drbd["resources"][res_name].has_key?("device") then
          resfile.puts "   device\t"+$drbd["resources"][res_name]["device"]+";"
        end
		if $drbd["resources"][res_name].has_key?("disk") then
          resfile.puts "   disk\t"+$drbd["resources"][res_name]["disk"]+";"
        end
		if $drbd["resources"][res_name].has_key?("meta-disk") then
          resfile.puts "   meta-disk\t"+$drbd["resources"][res_name]["meta-disk"]+";"
        end

        if $drbd["resources"][res_name].has_key?("disk_s") then
          resfile.puts "   disk {"
          $drbd["resources"][res_name]["disk_s"].each_key do |key|
            resfile.puts "      "+key+"\t"+$drbd["resources"][res_name]["disk_s"][key]+";"
          end
          resfile.puts "   }"
        end

        if $drbd["resources"][res_name].has_key?("syncer") then
          resfile.puts "   syncer {"
          $drbd["resources"][res_name]["syncer"].each_key do |key|
            resfile.puts "      "+key+"\t"+$drbd["resources"][res_name]["syncer"][key]+";"
          end
          resfile.puts "   }"
        end

        if $drbd["resources"][res_name].has_key?("net") then
          resfile.puts "   net {"
          $drbd["resources"][res_name]["net"].each_key do |key|
            resfile.puts "      "+key+"\t"+$drbd["resources"][res_name]["net"][key]+";"
          end
          resfile.puts "   }"
        end

        if $drbd["resources"][res_name].has_key?("startup") then
          resfile.puts "   startup {"
          $drbd["resources"][res_name]["startup"].each_key do |key|
            resfile.puts "      "+key+"\t"+$drbd["resources"][res_name]["startup"][key]+";"
          end
          resfile.puts "   }"
        end

        if $drbd["resources"][res_name].has_key?("handlers") then
          resfile.puts "   handlers {"
          $drbd["resources"][res_name]["handlers"].each_key do |key|
            resfile.puts "      "+key+"\t"+$drbd["resources"][res_name]["handlers"][key]+";"
          end
          resfile.puts "   }"
        end

        if $drbd["resources"][res_name].has_key?("on") then
          $drbd["resources"][res_name]["on"].each_key do |node_name|
            resfile.puts "   on "+node_name+" {"
            $drbd["resources"][res_name]["on"][node_name].each_key do |key|
              resfile.puts "      "+key+"\t"+$drbd["resources"][res_name]["on"][node_name][key]+";"
            end
            resfile.puts "   }"
          end
        end

		if $drbd["resources"][res_name].has_key?("stacked-on-top-of") then
		  $drbd["resources"][res_name]["stacked-on-top-of"].each_key do |rn|
		    resfile.puts "   stack_on_top_of "+rn+" {"
			$drbd["resources"][res_name]["stacked-on-top-of"][rn].each_key do |key|
			  resfile.puts "      "+key+"\t"+$drbd["resources"][res_name]["stacked-on-top-of"][rn][key]+";"
			end
			resfile.puts "   }"
		  end
		end

		if $drbd["resources"][res_name].has_key?("floating") then
		  $drbd["resources"][res_name]["floating"].each_key do |ipp|
		    if $drbd["resources"][res_name]["floating"][ipp] == {} then
			  resfile.puts "   floating "+ipp+";"
			else
			  resfile.puts "   floating "+ipp+" {"
			  $drbd["resources"][res_name]["floating"][ipp].each_key do |key|
			    resfile.puts "      "+key+"\t"+$drbd["resources"][res_name]["floating"][ipp][key]+";"
			  end
			  resfile.puts "   }"
			end
		  end
		end # <-- floating key
        resfile.puts "}"
		end # <-- File.open(seperate cfg file)
      end # <-- each resource section
    end # <-- has resources
  end # <-- File.open($drbdcfg)
end # <-- end of function

def commitChange()
  Dir.glob("/etc/drbd.d/*.YaST2new") { |newfile|
    origfile = newfile.split(".")[0..-2].join(".")
    if File.exist?(origfile) then
      File.rename(origfile, origfile+".YaST2save")
    end
    File.rename(newfile, origfile)
  }
  if not File.exist?($drbdcfg+".YaST2new") then
    return
  elsif File.exist?($drbdcfg) then
    File.rename($drbdcfg, $drbdcfg+".YaST2save")
  end
  File.rename($drbdcfg+".YaST2new", $drbdcfg)
end

# `Write (.drbd) means to write the file, other wise, the file is not written anyway

errlog($drbd.to_s)

$stdin.each do |line|
  errlog(line)
  line.chomp
  cmd = line.gsub(/^`?([a-zA-Z]+)\s+$/, '\1')
  path = line.gsub(/^`?([a-zA-Z]+)\s+\(([^,]*)(,.*)?\)$/, '\2').split('.')-[""]-["\n"]
  args = line.gsub(/^`?([a-zA-Z]+)\s+\(([^,]*)(,.*)?\)$/, '\3')
  if args.length != 0 then
    args[0] = ' '
    args = args.lstrip().rstrip()
    if args[0] == '"' then
      args = args[1..-2]
    end
  end
  case cmd
    when /Dir/
      doList(path)
    when /Read/
      doRead(path)
	when /Write/
	  doWrite(path, args)
	when /result/
	  exit
    when /.*/
      puts "nil"
  end
  $stdout.flush
end

