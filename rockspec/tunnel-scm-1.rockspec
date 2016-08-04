package = 'tunnel'
version = 'scm-1'

source = {
   url = 'git://github.com/zhangxiangxiao/tunnel.git'
}

description = {
   summary = 'Tunnel',
   detailed = 'A data driven framework for distributed computing in Torch 7.',
   homepage = 'https://github.com/zhangxiangxiao/tunnel',
   license = 'BSD'
}

dependencies = {
   'lua >= 5.1',
   'torch >= 7.0',
   'threads',
   'tds'
}

build = {
   type = 'builtin',
   modules = {
      ['tunnel.init'] = "tunnel/init.lua",
      ['tunnel.atomic'] = 'tunnel/atomic.lua',
      ['tunnel.block'] = 'tunnel/block.lua',
      ['tunnel.hash'] = 'tunnel/hash.lua',
      ['tunnel.printer'] = 'tunnel/printer.lua',
      ['tunnel.serializer'] = 'tunnel/serializer.lua',
      ['tunnel.share'] = 'tunnel/share.lua',
      ['tunnel.vector'] = 'tunnel/vector.lua'
   }
}
