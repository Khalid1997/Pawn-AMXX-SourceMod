#if defined _multimod_included_
#endinput
#endif
#define _multimod_included_

#include <multimod/multimod_const>
#include <multimod/multimod_base>
#include <multimod/multimod_settings>
#include <multimod/multimod_logging>
#include <multimod/multimod_stocks>


// Voting plugin is not required.
#if defined REQUIRE_PLUGIN
	#undef REQUIRE_PLUGIN
#endif
#include <multimod/multimod_vote>
#define REQUIRE_PLUGIN
