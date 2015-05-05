{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Authenticake.Nice (

    Nice(..)
  , NiceDenial

  ) where

import Authenticake.Authenticate

-- | The NiceAuthenticator authenticates everybody.
--   If Authenticator instances form a monoid under AuthenticatorAnd, then this
--   is the identity.
data Nice = Nice

data NiceDenial

instance Authenticator Nice where
  type NotAuthenticReason Nice s = NiceDenial
  type Subject Nice t = t
  type Challenge Nice s = ()
  authenticate Nice proxy subject challenge = return Nothing
