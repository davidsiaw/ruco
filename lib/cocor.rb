require "cocor/cocor"

include Cocor
module Cocor

	def Cocor.runtest(hello)
		cocor_test(hello)
	end

	def Cocor.compile(srcName, frameDir, nsName, outDir)
		cocor_compile(srcName, frameDir, nsName, outDir)
	end

end