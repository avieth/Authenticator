{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Authenticate.Authenticate (

    authenticate
  , Authenticated
  , AuthenticateDecision

  , Authenticator(..)
  , Authenticatable(..)

  ) where

import Control.RichConditional
import Data.Proxy

-- | The main user-facing function
authenticate
  :: forall authenticator t .
     ( Authenticator authenticator
     , Authenticatable authenticator t
     )
  => authenticator
  -> t
  -> Challenge authenticator t
  -> IO (AuthenticateDecision authenticator t)
authenticate a x c = do
  let subject = authenticationSubject (Proxy :: Proxy authenticator) x
  decision <- authenticatorDecision a (Proxy :: Proxy t) subject c
  -- The decision is positive in case of a failure, so we use Bad in the
  -- positive case and give Authenticated otherwise.
  return $ inCase decision Bad (OK (Authenticated x))

-- | Indicates that some value of type a is authenticated
--   It's important that we do not export Authenticated.
--   'authenticate' is the only function which will create Authenticated
--   values.
data Authenticated a = Authenticated a

-- | A decision about authentication for a value of some type a.
data AuthenticateDecision authenticator a
  = OK (Authenticated a)
  -- ^ Authenticated.
  | Bad (Failure authenticator)
  -- ^ Not authenticated.

instance PartialIf (AuthenticateDecision authenticator a) (Authenticated a) where
  indicate auth = case auth of
    OK x -> Just x
    _ -> Nothing

instance f ~ Failure authenticator => TotalIf (AuthenticateDecision authenticator a) (Authenticated a) f where
  decide auth = case auth of
    OK x -> Left x
    Bad x -> Right x

class Authenticator a where
  type Failure a :: *
  -- ^ Type to describe every possible reason for authentication failure.
  --   This may vary between Authenticators: for instance, a username/password
  --   based Authenticator can say "wrong password", "unrecognized username",
  --   or "database I/O problem", but an OAuth based Authenticator would say
  --   "invalid key" or something.
  type Subject a t :: *
  type Challenge a t :: *
  authenticatorDecision
    :: Authenticatable a t
    => a
    -> u t
    -- ^ A proxy; needed since Subject and Challenge are not injective.
    -> Subject a t
    -> Challenge a t
    -> IO (Maybe (Failure a))

class Authenticatable authenticator t where
  authenticationSubject :: u authenticator -> t -> Subject authenticator t
